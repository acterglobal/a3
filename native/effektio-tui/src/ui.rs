use anyhow::Result;
use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use std::io;
use std::sync::mpsc::Receiver;
use tui::{
    backend::{Backend, CrosstermBackend},
    layout::{Constraint, Direction, Layout},
    style::{Color, Modifier, Style},
    text::{Span, Spans},
    widgets::{Block, Borders, Tabs},
    Frame, Terminal,
};
use tui_logger::TuiLoggerWidget;

pub enum AppUpdate {
    SetUsername(String), // set the username
}

struct App<'a> {
    pub username: Option<String>,
    pub titles: Vec<&'a str>,
    pub index: usize,
}

impl<'a> App<'a> {
    fn new() -> App<'a> {
        App {
            titles: vec!["News", "Tasks", "Chat"],
            index: 0,
            username: None,
        }
    }

    pub fn apply(&mut self, update: AppUpdate) {
        match update {
            AppUpdate::SetUsername(u) => self.username = Some(u),
        }
    }

    pub fn next(&mut self) {
        self.index = (self.index + 1) % self.titles.len();
    }

    pub fn previous(&mut self) {
        if self.index > 0 {
            self.index -= 1;
        } else {
            self.index = self.titles.len() - 1;
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
    loop {
        terminal.draw(|f| ui(f, &app))?;

        if let Event::Key(key) = event::read()? {
            match key.code {
                KeyCode::Char('q') => return Ok(()),
                KeyCode::Right => app.next(),
                KeyCode::Left => app.previous(),
                _ => {}
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

    let block = Block::default().style(Style::default().bg(Color::Black).fg(Color::Magenta));
    f.render_widget(block, size);
    let titles = app
        .titles
        .iter()
        .map(|t| {
            let (first, rest) = t.split_at(1);
            Spans::from(vec![
                Span::styled(first, Style::default().fg(Color::Yellow)),
                Span::styled(rest, Style::default().fg(Color::Green)),
            ])
        })
        .collect();
    let tabs = Tabs::new(titles)
        .block(Block::default().borders(Borders::ALL).title("Tool"))
        .select(app.index)
        .style(Style::default().fg(Color::Cyan))
        .highlight_style(
            Style::default()
                .add_modifier(Modifier::BOLD)
                .bg(Color::Black),
        );
    f.render_widget(tabs, chunks[0]);
    let inner = match app.index {
        0 => Block::default().title("News").borders(Borders::ALL),
        1 => Block::default().title("Tasks").borders(Borders::ALL),
        2 => Block::default().title("Chat").borders(Borders::ALL),
        3 => Block::default().title("Inner 3").borders(Borders::ALL),
        _ => unreachable!(),
    };
    f.render_widget(inner, chunks[1]);

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

    let logger = TuiLoggerWidget::default()
        .style_error(Style::default().fg(Color::Red))
        .style_debug(Style::default().fg(Color::Green))
        .style_warn(Style::default().fg(Color::Yellow))
        .style_trace(Style::default().fg(Color::Gray))
        .style_info(Style::default().fg(Color::Blue))
        .block(Block::default().borders(Borders::ALL).title("Logs"))
        .style(Style::default().fg(Color::White).bg(Color::Black));

    f.render_widget(logger, chunks[3]);
}
