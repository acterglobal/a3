use anyhow::Result;
use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEvent},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use std::{io, time::Duration};
use std::{sync::mpsc::Receiver, time::Instant};
use tui::{
    backend::{Backend, CrosstermBackend},
    layout::{Constraint, Direction, Layout},
    style::{Color, Modifier, Style},
    text::{Span, Spans},
    widgets::{Block, Borders, Tabs},
    Frame, Terminal,
};
use tui_logger::{TuiLoggerWidget, TuiWidgetEvent};

pub enum AppUpdate {
    SetUsername(String), // set the username
}

#[derive(PartialEq, Eq)]
enum Widget {
    Tools,
    Main,
    Logs,
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

struct App<'a> {
    pub username: Option<String>,
    pub selected_widget: Widget,
    pub log_state: tui_logger::TuiWidgetState,
    pub tools: Vec<&'a str>,
    pub index: usize,
}

impl<'a> App<'a> {
    fn new() -> App<'a> {
        App {
            tools: vec!["News", "Tasks", "Chat"],
            index: 0,
            selected_widget: Widget::Tools,
            log_state: Default::default(),
            username: None,
        }
    }

    pub fn next_widget(&mut self) {
        self.selected_widget = self.selected_widget.next()
    }

    pub fn apply(&mut self, update: AppUpdate) {
        match update {
            AppUpdate::SetUsername(u) => self.username = Some(u),
        }
    }

    fn handle_key(&mut self, key: KeyEvent) -> bool {
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
                //..
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

pub fn run_ui(rx: Receiver<AppUpdate>) -> Result<()> {
    // setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    // create app and run it
    let app = App::new();
    let res = run_app(&mut terminal, app, rx);

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

fn run_app<B: Backend>(
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
                if app.handle_key(key) {
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
        .margin(2)
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

    let block = Block::default().style(Style::default().bg(Color::Black).fg(Color::LightGreen));
    f.render_widget(block, size);

    let titles = app
        .tools
        .iter()
        .map(|t| {
            let (first, rest) = t.split_at(1);
            Spans::from(vec![
                Span::styled(first, Style::default().fg(Color::Yellow)),
                Span::styled(rest, Style::default().fg(Color::Green)),
            ])
        })
        .collect();

    let mut block = Block::default().borders(Borders::ALL).title("Tool");
    if app.selected_widget == Widget::Tools {
        block = block.border_style(Style::default().fg(Color::Magenta));
    }
    let tabs = Tabs::new(titles)
        .block(block)
        .select(app.index)
        .highlight_style(
            Style::default()
                .add_modifier(Modifier::BOLD)
                .bg(Color::Black),
        );

    f.render_widget(tabs, chunks[0]);

    let mut main = match app.index {
        0 => Block::default().title("News").borders(Borders::ALL),
        1 => Block::default().title("Tasks").borders(Borders::ALL),
        2 => Block::default().title("Chat").borders(Borders::ALL),
        3 => Block::default().title("Inner 3").borders(Borders::ALL),
        _ => unreachable!(),
    };

    if app.selected_widget == Widget::Main {
        main = main.border_style(Style::default().fg(Color::Magenta));
    }
    f.render_widget(main, chunks[1]);

    let status = Tabs::new(vec![
        Spans::from(vec![Span::styled(
            app.username.clone().unwrap_or("".to_owned()),
            Style::default().fg(Color::Yellow),
        )]),
        //Span::styled(rest, Style::default().fg(Color::Green)),
    ])
    .block(Block::default().borders(Borders::ALL).title("Status"))
    .style(Style::default().fg(Color::Cyan));

    f.render_widget(status, chunks[2]);

    let mut block = Block::default().borders(Borders::ALL).title("Logs");
    if app.selected_widget == Widget::Logs {
        block = block.border_style(Style::default().fg(Color::Magenta));
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
