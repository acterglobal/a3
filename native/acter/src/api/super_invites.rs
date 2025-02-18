// internal API

use acter_core::super_invites::{api, CreateToken, Token, TokenInfo, UpdateToken};
use anyhow::{Context, Result};

use crate::{Client, RUNTIME};

pub struct SuperInviteInfo {
    token: TokenInfo,
}

impl SuperInviteInfo {
    fn new(token: TokenInfo) -> SuperInviteInfo {
        SuperInviteInfo { token }
    }
    pub fn create_dm(&self) -> bool {
        self.token.create_dm
    }

    pub fn rooms_count(&self) -> u32 {
        self.token.rooms_count
    }

    pub fn has_redeemed(&self) -> bool {
        self.token.has_redeemed
    }

    pub fn inviter_user_id_str(&self) -> String {
        self.token.inviter.user_id.to_string()
    }

    pub fn inviter_display_name_str(&self) -> Option<String> {
        self.token.inviter.display_name.clone()
    }

    pub fn inviter_avatar_url_str(&self) -> Option<String> {
        self.token
            .inviter
            .avatar_url
            .as_ref()
            .map(ToString::to_string)
    }
}

pub struct SuperInviteToken {
    token: Token,
}

impl SuperInviteToken {
    fn new(token: Token) -> SuperInviteToken {
        SuperInviteToken { token }
    }

    pub fn token(&self) -> String {
        self.token.token.to_string()
    }

    pub fn create_dm(&self) -> bool {
        self.token.create_dm
    }

    pub fn accepted_count(&self) -> u32 {
        self.token.accepted_count
    }

    pub fn rooms(&self) -> Vec<String> {
        self.token.rooms.clone()
    }

    pub fn update_builder(&self) -> SuperInvitesTokenUpdateBuilder {
        SuperInvitesTokenUpdateBuilder {
            token: CreateToken {
                token: Some(self.token()),
                create_dm: Some(self.create_dm()),
                rooms: self.rooms(),
            },
        }
    }
}

pub struct SuperInvites {
    client: Client,
}

pub struct SuperInvitesTokenUpdateBuilder {
    token: CreateToken,
}
impl Default for SuperInvitesTokenUpdateBuilder {
    fn default() -> Self {
        Self::new()
    }
}

impl SuperInvitesTokenUpdateBuilder {
    pub fn new() -> SuperInvitesTokenUpdateBuilder {
        SuperInvitesTokenUpdateBuilder {
            token: CreateToken::default(),
        }
    }

    pub fn token(&mut self, token: String) {
        self.token.token = Some(token);
    }
    pub fn add_room(&mut self, room: String) {
        self.token.rooms.push(room);
    }
    pub fn remove_room(&mut self, room: String) {
        self.token.rooms.retain(|a| a != &room);
    }
    pub fn create_dm(&mut self, val: bool) {
        self.token.create_dm = Some(val);
    }

    fn has_token(&self) -> bool {
        self.token.token.is_some()
    }

    fn into_update_token(self) -> Option<UpdateToken> {
        let CreateToken {
            create_dm,
            rooms,
            token,
        } = self.token;
        token.map(|token| UpdateToken {
            token,
            create_dm: create_dm.unwrap_or_default(),
            rooms,
        })
    }
}

impl SuperInvites {
    pub async fn tokens(&self) -> Result<Vec<SuperInviteToken>> {
        let c = self.client.clone();
        RUNTIME
            .spawn(async move {
                let req = api::list::Request::new();
                let resp = c.send(req).await?;
                Ok(resp
                    .tokens
                    .into_iter()
                    .map(SuperInviteToken::new)
                    .collect::<Vec<_>>())
            })
            .await?
    }

    pub fn new_token_updater(&self) -> SuperInvitesTokenUpdateBuilder {
        SuperInvitesTokenUpdateBuilder::new()
    }

    pub async fn redeem(&self, token: String) -> Result<Vec<String>> {
        let c = self.client.clone();
        RUNTIME
            .spawn(async move {
                let req = api::redeem::Request::new(token);
                let resp = c.send(req).await?;
                Ok(resp.rooms)
            })
            .await?
    }

    pub async fn info(&self, token: String) -> Result<SuperInviteInfo> {
        let c = self.client.clone();
        RUNTIME
            .spawn(async move {
                let req = api::info::Request::new(token);
                let resp = c.send(req).await?;
                Ok(SuperInviteInfo::new(resp.info))
            })
            .await?
    }

    pub async fn create_or_update_token(
        &self,
        builder: Box<SuperInvitesTokenUpdateBuilder>,
    ) -> Result<SuperInviteToken> {
        let c = self.client.clone();
        RUNTIME
            .spawn(async move {
                Ok(if builder.has_token() {
                    // we just checked for it
                    let token = builder
                        .into_update_token()
                        .context("Unable to get update token from builder")?;
                    let req = api::update::Request::new(token);
                    let resp = c.send(req).await?;
                    resp.token
                } else {
                    let token = builder.token;
                    let req = api::create::Request::new(token);
                    let resp = c.send(req).await?;
                    resp.token
                })
            })
            .await?
            .map(SuperInviteToken::new)
    }

    pub async fn delete(&self, token: String) -> Result<bool> {
        let c = self.client.clone();
        RUNTIME
            .spawn(async move {
                let req = api::delete::Request::new(token);
                c.send(req).await?;
                Ok(true)
            })
            .await?
    }
}

impl Client {
    pub fn super_invites(&self) -> SuperInvites {
        SuperInvites {
            client: self.clone(),
        }
    }
}
