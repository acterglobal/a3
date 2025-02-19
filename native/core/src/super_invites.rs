use matrix_sdk_base::ruma::{OwnedMxcUri, OwnedUserId};
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Token {
    pub token: String,
    pub create_dm: bool,
    pub accepted_count: u32,
    pub rooms: Vec<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct TokenOwner {
    pub user_id: OwnedUserId,
    pub display_name: Option<String>,
    pub avatar_url: Option<OwnedMxcUri>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct TokenInfo {
    pub rooms_count: u32,
    pub create_dm: bool,
    pub has_redeemed: bool,
    pub inviter: TokenOwner,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
pub struct CreateToken {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub token: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub create_dm: Option<bool>,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub rooms: Vec<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct UpdateToken {
    pub token: String,
    pub create_dm: bool,
    pub rooms: Vec<String>,
}

pub mod api {
    pub mod list {

        use matrix_sdk_base::ruma::{
            api::{request, response, Metadata},
            metadata,
        };

        use super::super::Token;

        const METADATA: Metadata = metadata! {
            method: GET,
            rate_limited: false,
            authentication: AccessToken,
            history: {
                unstable => "/_synapse/client/super_invites/tokens",
            }
        };

        #[request]
        pub struct Request {}

        impl Request {
            pub fn new() -> Self {
                Request {}
            }
        }
        impl Default for Request {
            fn default() -> Self {
                Self::new()
            }
        }

        #[response]
        #[derive(Default)]
        pub struct Response {
            pub tokens: Vec<Token>,
        }

        impl Response {
            /// Creates an empty `Response`.
            pub fn new() -> Self {
                Default::default()
            }
        }
    }

    pub mod create {

        use matrix_sdk_base::ruma::{
            api::{request, response, Metadata},
            metadata,
        };

        use super::super::{CreateToken, Token};

        const METADATA: Metadata = metadata! {
            method: POST,
            rate_limited: false,
            authentication: AccessToken,
            history: {
                unstable => "/_synapse/client/super_invites/tokens",
            }
        };

        #[request]
        pub struct Request {
            #[ruma_api(body)]
            pub token: CreateToken,
        }

        impl Request {
            pub fn new(token: CreateToken) -> Self {
                Request { token }
            }
        }

        #[response]
        pub struct Response {
            pub token: Token,
        }
    }

    pub mod update {

        use matrix_sdk_base::ruma::{
            api::{request, response, Metadata},
            metadata,
        };

        use super::super::{Token, UpdateToken};

        const METADATA: Metadata = metadata! {
            method: POST,
            rate_limited: false,
            authentication: AccessToken,
            history: {
                unstable => "/_synapse/client/super_invites/tokens",
            }
        };

        #[request]
        pub struct Request {
            #[ruma_api(body)]
            pub token: UpdateToken,
        }

        impl Request {
            pub fn new(token: UpdateToken) -> Self {
                Request { token }
            }
        }

        #[response]
        pub struct Response {
            pub token: Token,
        }
    }

    pub mod delete {

        use matrix_sdk_base::ruma::{
            api::{request, response, Metadata},
            metadata,
        };

        const METADATA: Metadata = metadata! {
            method: DELETE,
            rate_limited: false,
            authentication: AccessToken,
            history: {
                unstable => "/_synapse/client/super_invites/tokens",
            }
        };

        #[request]
        pub struct Request {
            #[ruma_api(query)]
            pub token: String,
        }

        impl Request {
            pub fn new(token: String) -> Self {
                Request { token }
            }
        }

        #[response]
        pub struct Response {}
    }

    pub mod redeem {

        use matrix_sdk_base::ruma::{
            api::{request, response, Metadata},
            metadata,
        };

        const METADATA: Metadata = metadata! {
            method: POST,
            rate_limited: false,
            authentication: AccessToken,
            history: {
                unstable => "/_synapse/client/super_invites/redeem",
            }
        };

        #[request]
        pub struct Request {
            #[ruma_api(query)]
            pub token: String,
        }

        impl Request {
            pub fn new(token: String) -> Self {
                Request { token }
            }
        }

        #[response]
        pub struct Response {
            pub rooms: Vec<String>,
        }
    }

    pub mod info {

        use matrix_sdk_base::ruma::{
            api::{request, response, Metadata},
            metadata,
        };

        use super::super::TokenInfo;

        const METADATA: Metadata = metadata! {
            method: GET,
            rate_limited: false,
            authentication: AccessToken,
            history: {
                unstable => "/_synapse/client/super_invites/info",
            }
        };

        #[request]
        pub struct Request {
            #[ruma_api(query)]
            pub token: String,
        }

        impl Request {
            pub fn new(token: String) -> Self {
                Request { token }
            }
        }

        #[response]
        pub struct Response {
            #[ruma_api(body)]
            pub info: TokenInfo,
        }
    }
}
