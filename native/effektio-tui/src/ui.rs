#![allow(dead_code)]
use anyhow::Result;
use clap::crate_version;
use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEvent},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use dialoguer::{Input, Select};
use effektio::{Conversation, Group, HistoryLoadState};
use effektio_core::models::TaskList;
use futures::future::join_all;
use std::{io, time::Duration};
use std::{sync::mpsc::Receiver, time::Instant};
use tui::{
    backend::{Backend, CrosstermBackend},
    layout::{Alignment, Constraint, Direction, Layout},
    style::{Color, Modifier, Style},
    text::{Span, Spans},
    widgets::{Block, Borders, Tabs},
    Frame, Terminal,
};
use tui_logger::{TuiLoggerWidget, TuiWidgetEvent};

const PRIMARY: Color = Color::Rgb(236, 39, 88);
const SECONDARY: Color = Color::Rgb(35, 175, 194);
const TERTIARY: Color = Color::Rgb(92, 42, 128);
const BG_GRAY: Color = Color::Rgb(151, 151, 151);
const BG_DARK: Color = Color::Rgb(51, 53, 64);
const BG_DARKER: Color = Color::Rgb(47, 49, 62);

pub enum AppUpdate {
    SetUsername(String), // set the username
    SetSynced(bool),     // set the synced state
    UpdateConversations(Vec<Conversation>),
    UpdateGroups(Vec<Group>),
    SetHistoryLoadState(HistoryLoadState),
}

#[derive(PartialEq, Eq)]
enum Widget {
    Tools,
    Main,
    Logs,
}

#[derive(Clone, Debug)]
struct ChatStats {
    total: u32,
    unread: u32,
    notifications: u32,
}

#[derive(Clone, Debug)]
enum Tool {
    News,
    Tasks(Vec<TaskList>),
    Chat(Option<ChatStats>),
}

impl Tool {
    fn name(&self) -> String {
        match self {
            Tool::News => "News".to_owned(),
            Tool::Tasks(_) => "Tasks".to_owned(),
            Tool::Chat(stats) => match stats {
                Some(s) => {
                    format!("Chat ({}/{})", s.unread, s.total)
                }
                _ => "Chat".to_owned(),
            },
        }
    }

    fn is_tasks(&self) -> bool {
        matches!(self, Tool::Tasks(_))
    }

    fn is_chat(&self) -> bool {
        matches!(self, Tool::Chat(_))
    }

    fn update_chat_stats(&mut self, new_stats: ChatStats) {
        if !self.is_chat() {
            unimplemented!("What are you doing here?")
        }

        *self = Tool::Chat(Some(new_stats))
    }

    fn all() -> [Self; 3] {
        [
            Tool::Tasks(Default::default()),
            Tool::News,
            Tool::Chat(None),
        ]
    }
}

impl Widget {
    fn next(&self) -> Self {
        match self {
            Widget::Tools => Widget::Main,
            Widget::Main => Widget::Logs,
            Widget::Logs => Widget::Tools,
        }
    }
}

struct App {
    pub username: Option<String>,
    pub selected_widget: Widget,
    pub log_state: tui_logger::TuiWidgetState,
    pub tools: Vec<Tool>,
    pub groups: Vec<Group>,
    pub conversations: Vec<Conversation>,
    pub history_load_state: HistoryLoadState,
    pub index: usize,
    pub synced: bool,
}

impl App {
    fn new() -> App {
        App {
            tools: Tool::all().to_vec(),
            index: 0,
            selected_widget: Widget::Tools,
            log_state: Default::default(),
            groups: Default::default(),
            conversations: Default::default(),
            history_load_state: Default::default(),
            username: None,
            synced: false,
        }
    }

    pub fn next_widget(&mut self) {
        self.selected_widget = self.selected_widget.next()
    }

    pub fn apply(&mut self, update: AppUpdate) {
        match update {
            AppUpdate::SetUsername(u) => self.username = Some(u),
            AppUpdate::SetSynced(synced) => self.synced = synced,
            AppUpdate::UpdateGroups(groups) => {
                self.groups = groups;
            }
            AppUpdate::SetHistoryLoadState(state) => {
                self.history_load_state = state;
            }
            AppUpdate::UpdateConversations(convos) => {
                for m in self.tools.iter_mut() {
                    if m.is_chat() {
                        m.update_chat_stats(ChatStats {
                            total: convos.len() as u32,
                            unread: 0,
                            notifications: 0,
                        });
                        break;
                    }
                }
                self.conversations = convos;
            }
        }
    }

    pub fn selected_tool(&self) -> &Tool {
        &self.tools[self.index]
    }

    async fn handle_key(&mut self, key: KeyEvent) -> bool {
        // true means exit
        match key.code {
            KeyCode::Esc => return true,
            KeyCode::Tab => {
                self.next_widget();
                return false;
            }
            _ => {}
        }

        match self.selected_widget {
            Widget::Tools => match key.code {
                KeyCode::Right => self.next_tool(),
                KeyCode::Left => self.previous_tool(),
                _ => {}
            },
            Widget::Logs => match key.code {
                KeyCode::Up => {
                    self.log_state.transition(&TuiWidgetEvent::PrevPageKey);
                }
                KeyCode::Down => {
                    self.log_state.transition(&TuiWidgetEvent::NextPageKey);
                }
                _ => {}
            },
            Widget::Main => {
                match key.code {
                    KeyCode::Char('n') if self.selected_tool().is_tasks() => {
                        let groups = &self.groups;
                        let names: Vec<String> = join_all(groups.iter().map(|g| g.display_name()))
                            .await
                            .into_iter()
                            .collect::<Result<Vec<_>>>()
                            .unwrap();

                        let list_title = Input::<String>::new()
                            .with_prompt("List Title")
                            .interact_text()
                            .unwrap();

                        let chosen: usize = Select::new()
                            .with_prompt("Under which Group?")
                            .items(&names)
                            .interact()
                            .unwrap();

                        let group = &groups[chosen];
                        let mut tl_draft = group.task_list_draft().unwrap();
                        tl_draft.name(list_title);

                        tl_draft.send().await.unwrap();
                    }
                    _ => {
                        // ...
                    }
                }
            }
        }

        false
    }

    pub fn next_tool(&mut self) {
        self.index = (self.index + 1) % self.tools.len();
    }

    pub fn previous_tool(&mut self) {
        if self.index > 0 {
            self.index -= 1;
        } else {
            self.index = self.tools.len() - 1;
        }
    }
}

pub async fn run_ui(rx: Receiver<AppUpdate>) -> Result<()> {
    // setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    // create app and run it
    let app = App::new();
    let res = run_app(&mut terminal, app, rx).await;

    // restore terminal
    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    if let Err(err) = res {
        println!("{:?}", err)
    }

    Ok(())
}

async fn run_app<B: Backend>(
    terminal: &mut Terminal<B>,
    mut app: App,
    rx: Receiver<AppUpdate>,
) -> io::Result<()> {
    let tick_rate = Duration::from_millis(250);
    let mut last_tick = Instant::now();

    loop {
        terminal.draw(|f| ui(f, &app))?;

        let timeout = tick_rate
            .checked_sub(last_tick.elapsed())
            .unwrap_or_else(|| Duration::from_secs(0));
        if crossterm::event::poll(timeout)? {
            if let Event::Key(key) = event::read()? {
                if app.handle_key(key).await {
                    return Ok(());
                }
            }
        }
        loop {
            //apply all the changes
            match rx.try_recv() {
                Ok(update) => app.apply(update),
                Err(std::sync::mpsc::TryRecvError::Empty) => break, // nothing else to process
                Err(std::sync::mpsc::TryRecvError::Disconnected) => return Ok(()), // time to quit
            }
        }
        if last_tick.elapsed() >= tick_rate {
            //app.on_tick();
            last_tick = Instant::now();
        }
    }
}

fn ui<B: Backend>(f: &mut Frame<B>, app: &App) {
    let size = f.size();
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .margin(1)
        .constraints(
            [
                Constraint::Length(3),
                Constraint::Min(0),
                Constraint::Length(3),
                Constraint::Length(6),
            ]
            .as_ref(),
        )
        .split(size);

    let block = Block::default()
        .style(Style::default().bg(BG_DARKER).fg(SECONDARY))
        .title_alignment(Alignment::Center)
        .title(format!(" effektio {:}", crate_version!()));
    f.render_widget(block, size);

    let titles = app
        .tools
        .iter()
        .map(|t| {
            Spans::from(vec![Span::styled(
                String::from(t.name()),
                Style::default().fg(TERTIARY),
            )])
        })
        .collect();

    let mut block = Block::default().borders(Borders::ALL).title(" Tool ");
    if app.selected_widget == Widget::Tools {
        block = block.border_style(Style::default().fg(PRIMARY));
    }
    let tabs = Tabs::new(titles)
        .block(block)
        .select(app.index)
        .highlight_style(Style::default().add_modifier(Modifier::BOLD).fg(PRIMARY));

    f.render_widget(tabs, chunks[0]);

    let mut main = Block::default()
        .title(format!(" {:} ", app.selected_tool().name()))
        .borders(Borders::ALL);

    if app.selected_widget == Widget::Main {
        main = main.border_style(Style::default().fg(PRIMARY));
    }
    f.render_widget(main, chunks[1]);

    let mut titles = vec![
        Spans::from(vec![Span::styled(
            app.username.clone().unwrap_or("".to_owned()),
            Style::default().fg(BG_GRAY),
        )]),
        Spans::from(vec![Span::styled(
            format!("synced: {}", app.synced),
            Style::default().fg(BG_GRAY),
        )]),
    ];
    if !app.history_load_state.is_done_loading() {
        titles.push(Spans::from(vec![Span::styled(
            format!(
                "{} / {} groups history loaded",
                app.history_load_state.loaded_groups, app.history_load_state.total_groups
            ),
            Style::default().fg(BG_GRAY),
        )]));
    } else {
        titles.push(Spans::from(vec![Span::styled(
            format!("{} Groups", app.groups.len()),
            Style::default().fg(BG_GRAY),
        )]));
    }

    let status = Tabs::new(titles)
        .block(Block::default().borders(Borders::ALL).title(" Status "))
        .style(Style::default().fg(BG_GRAY));

    f.render_widget(status, chunks[2]);

    let mut block = Block::default().borders(Borders::ALL).title(" Logs ");
    if app.selected_widget == Widget::Logs {
        block = block.border_style(Style::default().fg(PRIMARY));
    }

    let mut logger = TuiLoggerWidget::default()
        .style_error(Style::default().fg(Color::Red))
        .style_debug(Style::default().fg(Color::Green))
        .style_warn(Style::default().fg(Color::Yellow))
        .style_trace(Style::default().fg(Color::Gray))
        .style_info(Style::default().fg(Color::Blue))
        .block(block);

    logger.state(&app.log_state);

    f.render_widget(logger, chunks[3]);
}
