#![allow(dead_code)]
use acter::{Conversation, Group, HistoryLoadState, Task, TaskList};
use anyhow::Result;
use async_broadcast::Receiver as Subscription;
use clap::crate_version;
use crossterm::{
    event::{self, DisableMouseCapture, Event, KeyCode, KeyEvent},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use std::{
    io,
    sync::mpsc::Receiver,
    time::{Duration, Instant},
};
use tui::{
    backend::{Backend, CrosstermBackend},
    layout::{Alignment, Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Span, Spans, Text},
    widgets::{Block, Borders, List, ListItem, ListState, Tabs},
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
    SetTasksList(Vec<TaskList>),
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

#[derive(Clone, Debug, Default)]
struct TasksState {
    task_lists_list_state: ListState,
    tasks_list_state: ListState,
    selected: Option<TaskList>,
    task_lists: Vec<TaskList>,
    receivers: Vec<Subscription<()>>,
    tasks: Vec<Task>,
}

pub fn next(list_state: &mut ListState, list_len: usize) {
    if list_len == 0 {
        return;
    }
    let Some(current) = list_state.selected() else {
        list_state.select(Some(0));
        return
    };

    let next = current + 1;
    if next < list_len {
        list_state.select(Some(next));
    }
}

pub fn prev(list_state: &mut ListState) {
    let current = list_state.selected().unwrap_or_default();
    if current > 0 {
        list_state.select(Some(current - 1))
    }
}
impl TasksState {
    fn fresh(task_lists: Vec<TaskList>) -> Self {
        TasksState {
            task_lists_list_state: Default::default(),
            tasks_list_state: Default::default(),
            selected: None,
            task_lists,
            receivers: Default::default(),
            tasks: Default::default(),
        }
    }

    async fn tick(&mut self) {
        let mut update = false;
        for t in self.receivers.iter_mut() {
            if t.try_recv().is_ok() {
                // consume
                update = true;
            }
        }

        if update {
            tracing::trace!("refreshing upon tick");
            if let Some(t) = &self.selected.clone() {
                self.refresh(t).await;
            }
        }
    }

    async fn refresh(&mut self, task_list: &TaskList) {
        self.tasks = task_list.tasks().await.unwrap();
        self.receivers = self.tasks.iter().map(|t| t.subscribe()).collect();
        // self.receivers.push(task_list.subscribe());
    }

    fn select_next(&mut self) {
        if self.selected.is_some() {
            next(&mut self.tasks_list_state, self.tasks.len());
        } else {
            next(&mut self.task_lists_list_state, self.task_lists.len());
        }
    }
    async fn select(&mut self) {
        if self.selected.is_some() {
            if let Some(idx) = self.tasks_list_state.selected() {
                let Some(task) = self.tasks.get(idx) else {
                    panic!("can't be readed");
                };

                let resp = if task.is_done() {
                    tracing::trace!(?task, "marking undone");
                    task.update_builder().unwrap().mark_undone().send().await
                } else {
                    tracing::trace!(?task, "marking done");
                    task.update_builder().unwrap().mark_done().send().await
                };

                match resp {
                    Err(error) => {
                        tracing::error!(?task, ?error, "updating task failed");
                    }
                    Ok(event_id) => {
                        tracing::trace!(?task, ?event_id, "updating accepted");
                    }
                }
            }
        } else if let Some(selected) = self
            .task_lists_list_state
            .selected()
            .and_then(|idx| self.task_lists.get(idx).cloned())
        {
            tracing::trace!(?selected, "selecting");
            self.refresh(&selected).await;
            self.selected = Some(selected.clone());
        }
    }

    fn select_prev(&mut self) {
        if self.selected.is_some() {
            if self.tasks.is_empty() {
                return;
            }
            prev(&mut self.tasks_list_state);
        } else {
            if self.task_lists.is_empty() {
                return;
            }
            prev(&mut self.task_lists_list_state);
        }
    }

    async fn handle_key(&mut self, key: KeyEvent) -> bool {
        match key.code {
            KeyCode::Down => {
                self.select_next();
                true
            }
            KeyCode::Enter => {
                self.select().await;
                true
            }
            KeyCode::Up => {
                self.select_prev();
                true
            }
            KeyCode::Right => {
                if self.selected.is_none() {
                    self.select().await;
                }
                true
            }
            KeyCode::Esc | KeyCode::Left => {
                if self.selected.is_some() {
                    self.selected = None;
                    true
                } else {
                    false
                }
            }
            // KeyCode::Char('n') => {
            //     let groups = &self.groups;
            //     let names: Vec<String> =
            //         join_all(groups.iter().map(|g| g.display_name()))
            //             .await
            //             .into_iter()
            //             .map(|d| d.map(|i| format!("{}", i)))
            //             .collect::<Result<Vec<_>, StoreError>>()
            //             .unwrap();

            //     let list_title = Input::<String>::new()
            //         .with_prompt("List Title")
            //         .interact_text()
            //         .unwrap();

            //     let chosen: usize = Select::new()
            //         .with_prompt("Under which Group?")
            //         .items(&names)
            //         .interact()
            //         .unwrap();

            //     let group = &groups[chosen];
            //     let mut tl_draft = group.task_list_draft().unwrap();
            //     tl_draft.name(list_title);

            //     tl_draft.send().await.unwrap();
            //     true
            // }
            _ => false,
        }
    }

    fn render<B: Backend>(&mut self, f: &mut Frame<B>, area: Rect, block_border_style: Style) {
        if let Some(selected) = &self.selected {
            let ls = List::new(
                self.tasks
                    .iter()
                    .map(|t| {
                        if t.is_done() {
                            format!(" [x] {:}", t.title())
                        } else if let Some(p) = t.percent() {
                            format!(" {p}% {:}", t.title())
                        } else {
                            format!(" [ ] {:}", t.title())
                        }
                    })
                    .map(|s| ListItem::new(Text::from(s)))
                    .collect::<Vec<_>>(),
            )
            .highlight_style(Style::default().add_modifier(Modifier::BOLD).fg(PRIMARY))
            .block(
                Block::default()
                    .title(format!(" [🗹] > {:}", selected.name()))
                    .borders(Borders::ALL)
                    .border_style(block_border_style),
            );

            f.render_stateful_widget(ls, area, &mut self.tasks_list_state);
        } else {
            let ls = List::new(
                self.task_lists
                    .iter()
                    .map(|l| ListItem::new(Text::from(l.name())))
                    .collect::<Vec<_>>(),
            )
            .highlight_style(Style::default().add_modifier(Modifier::BOLD).fg(PRIMARY))
            .block(
                Block::default()
                    .title(" Tasks 🗹")
                    .borders(Borders::ALL)
                    .border_style(block_border_style),
            );

            f.render_stateful_widget(ls, area, &mut self.task_lists_list_state);
        }
    }
}

#[derive(Clone, Debug)]
enum Tool {
    News,
    Tasks(TasksState),
    Chat(Option<ChatStats>),
}

impl Tool {
    fn name(&self) -> String {
        match self {
            Tool::News => "News".to_owned(),
            Tool::Tasks(TasksState { task_lists, .. }) => {
                if task_lists.is_empty() {
                    "Tasks".to_owned()
                } else {
                    format!("Tasks ({:})", task_lists.len())
                }
            }
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

    fn set_tasks(&mut self, t: Vec<TaskList>) {
        if !self.is_tasks() {
            unimplemented!("What are you doing here?")
        }
        tracing::info!(len = t.len(), "settin tasks");
        *self = Tool::Tasks(TasksState::fresh(t))
    }

    fn all() -> [Self; 3] {
        [
            Tool::Tasks(Default::default()),
            Tool::News,
            Tool::Chat(None),
        ]
    }

    async fn handle_key(&mut self, key: KeyEvent) -> bool {
        match self {
            Tool::Tasks(task_state) => task_state.handle_key(key).await,
            _ => false,
        }
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
    pub logs_fullscreen: bool,
    pub tools: Vec<Tool>,
    pub groups: Vec<Group>,
    pub conversations: Vec<Conversation>,
    pub history_load_state: HistoryLoadState,
    pub index: usize,
    pub synced: bool,
}

impl App {
    fn new(logs_fullscreen: bool) -> App {
        let selected_widget = if logs_fullscreen {
            Widget::Logs
        } else {
            Widget::Tools
        };
        App {
            tools: Tool::all().to_vec(),
            index: 0,
            logs_fullscreen,
            selected_widget,
            log_state: Default::default(),
            groups: Default::default(),
            conversations: Default::default(),
            history_load_state: Default::default(),
            username: None,
            synced: false,
        }
    }

    async fn on_tick(&mut self) {
        if let Tool::Tasks(t) = self.selected_tool_mut() {
            t.tick().await;
        };
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
            AppUpdate::SetTasksList(t) => {
                for m in self.tools.iter_mut() {
                    if m.is_tasks() {
                        m.set_tasks(t);
                        break;
                    }
                }
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

    pub fn selected_tool_mut(&mut self) -> &mut Tool {
        &mut self.tools[self.index]
    }
    async fn handle_key(&mut self, key: KeyEvent) -> bool {
        let handled = match self.selected_widget {
            Widget::Tools => match key.code {
                KeyCode::Right => {
                    self.next_tool();
                    true
                }
                KeyCode::Left => {
                    self.previous_tool();
                    true
                }
                _ => false,
            },
            Widget::Logs => match key.code {
                KeyCode::Char(c) if c == 'f' => {
                    self.logs_fullscreen = !self.logs_fullscreen;
                    true
                }
                KeyCode::Up => {
                    self.log_state.transition(&TuiWidgetEvent::PrevPageKey);
                    true
                }
                KeyCode::Down => {
                    self.log_state.transition(&TuiWidgetEvent::NextPageKey);
                    true
                }
                _ => false,
            },
            Widget::Main => self.selected_tool_mut().handle_key(key).await,
        };

        if !handled {
            // true means exit
            match key.code {
                KeyCode::Esc => return true,
                KeyCode::Tab if !self.logs_fullscreen => {
                    self.next_widget();
                    return false;
                }
                _ => {}
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

pub async fn run_ui(rx: Receiver<AppUpdate>, logs_fullscreen: bool) -> Result<()> {
    // setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, DisableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    // create app and run it
    let app = App::new(logs_fullscreen);
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
        println!("{err:?}")
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
        terminal.draw(|f| ui(f, &mut app))?;

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
            app.on_tick().await;
            last_tick = Instant::now();
        }
    }
}

fn ui<B: Backend>(f: &mut Frame<B>, app: &mut App) {
    let size = f.size();
    let constraints = if app.logs_fullscreen {
        [
            Constraint::Length(3),
            Constraint::Min(0),
            Constraint::Length(3),
        ]
        .as_ref()
    } else {
        [
            Constraint::Length(3),
            Constraint::Min(0),
            Constraint::Length(3),
            Constraint::Length(6),
        ]
        .as_ref()
    };

    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .margin(1)
        .constraints(constraints)
        .split(size);

    let block = Block::default()
        .style(Style::default().bg(BG_DARKER).fg(SECONDARY))
        .title_alignment(Alignment::Center)
        .title(format!(" acter {:}", crate_version!()));
    f.render_widget(block, size);

    let titles = app
        .tools
        .iter()
        .map(|t| Spans::from(vec![Span::styled(t.name(), Style::default().fg(TERTIARY))]))
        .collect();

    let mut block = Block::default().borders(Borders::ALL).title(" Tool ");
    if app.selected_widget == Widget::Tools {
        block = block.border_style(Style::default().fg(PRIMARY));
    }
    let tabs = Tabs::new(titles)
        .block(block)
        .select(app.index)
        .highlight_style(Style::default().add_modifier(Modifier::BOLD).fg(PRIMARY));

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

    let mut block = Block::default().borders(Borders::ALL).title(" Logs ");
    if app.selected_widget == Widget::Logs {
        block = block.border_style(Style::default().fg(PRIMARY));
    }

    let logger = TuiLoggerWidget::default()
        .style_error(Style::default().fg(Color::Red))
        .style_debug(Style::default().fg(Color::Green))
        .style_warn(Style::default().fg(Color::Yellow))
        .style_trace(Style::default().fg(Color::Gray))
        .style_info(Style::default().fg(Color::Blue))
        .block(block)
        .state(&app.log_state);

    f.render_widget(tabs, chunks[0]);
    f.render_widget(status, chunks[2]);
    if app.logs_fullscreen {
        f.render_widget(logger, chunks[1]);
        return;
    }

    f.render_widget(logger, chunks[3]);
    let border_style = if app.selected_widget == Widget::Main {
        Style::default().fg(PRIMARY)
    } else {
        Style::default()
    };

    match app.selected_tool_mut() {
        Tool::Tasks(tasks_state) if !tasks_state.task_lists.is_empty() => {
            tasks_state.render(f, chunks[1], border_style);
        }
        t => {
            let default_block = Block::default()
                .title(format!(" {:} ", t.name()))
                .borders(Borders::ALL)
                .border_style(border_style);
            f.render_widget(default_block, chunks[1]);
        }
    };
}
