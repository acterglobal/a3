pub mod api {

    pub mod create {
        #![allow(non_snake_case)]

        use matrix_sdk_base::ruma::{
            api::{request, response, Metadata},
            metadata,
        };
        use serde::Serialize;
        use serde;


        #[derive(Serialize, Default, Debug, Clone)]
        #[serde(rename_all="kebab-case")]
        enum RequestType {
            #[default]
            Ref
        }

        use crate::events::RefDetails;

        const METADATA: Metadata = metadata! {
            method: PUT,
            rate_limited: false,
            authentication: AccessToken,
            history: {
                unstable => "/_synapse/client/share_link/",
            }
        };

        #[request]
        pub struct Request {
            #[serde(flatten)]
            inner: RefDetails,
            #[serde(rename="type")]
            req_type: RequestType,
        }

        impl Request {
            pub fn new(inner: RefDetails) -> Self {
                Request { inner, req_type: Default::default() }
            }
        }

        #[response]
        pub struct Response {
            pub url: String,
            pub targetUri: String,
        }
    }
}
