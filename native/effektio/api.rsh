
/// Initialize logging
fn init_logging(filter: Option<string>) -> Result<()>;


/// Create a new client for homeserver at url with storage at data_path
fn new_client(home_url: string, data_path: string) -> Result<Client>;

fn echo(inp: string) -> Result<string>;

/// Main entry point for `effektio`.
object Client {
    /// Whether the client is logged in
    fn logged_in() -> Future<bool>;

    // fn login(user: &str,  ) -> Future<

    // fn avatar_url() -> Future<>;
}