use anyhow::Result;
use effektio::api::{login_new_client, device_id};
use futures::stream::StreamExt;
use tempfile::TempDir;

#[tokio::test]
async fn one_verifies_another_under_same_account() -> Result<()> {
    let _ = env_logger::try_init();

    let tmp_dir = TempDir::new()?;
    let one = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@sisko:ds9.effektio.org".to_owned(),
        "sisko".to_owned(),
    )
    .await?;
    let one_syncer = one.start_sync();
    let mut one_synced = one_syncer.get_first_synced_rx().expect("not yet read");
    while one_synced.next().await != Some(true) {} // let's wait for it to have synced

    tokio::spawn(async move {
        let mut rx = one_syncer.get_emoji_verification_event_rx().expect("one should get event listener");
        loop {
            match rx.try_next() {
                Ok(Some(event)) => {
                    println!("one: {}", event.get_event_name());
                    match event.get_event_name().as_str() {
                        "AnyToDeviceEvent::KeyVerificationRequest" => {}
                        "AnyToDeviceEvent::KeyVerificationReady" => {}
                        "AnyToDeviceEvent::KeyVerificationStart" => {}
                        "AnyToDeviceEvent::KeyVerificationCancel" => {
                            break;
                        }
                        "AnyToDeviceEvent::KeyVerificationAccept" => {}
                        "AnyToDeviceEvent::KeyVerificationKey" => {}
                        "AnyToDeviceEvent::KeyVerificationMac" => {}
                        "AnyToDeviceEvent::KeyVerificationDone" => {
                            break;
                        }
                        _ => {}
                    }
                }
                Ok(None) => {}
                Err(e) => {}
            }
        }
    });

    let tmp_dir = TempDir::new()?;
    println!("123");
    let another = login_new_client(
        tmp_dir.path().to_str().expect("always works").to_owned(),
        "@sisko:ds9.effektio.org".to_owned(),
        "sisko".to_owned(),
    )
    .await?;
    println!("123");
    let another_syncer = another.start_sync();
    let mut another_synced = another_syncer.get_first_synced_rx().expect("not yet read");
    println!("123");
    while another_synced.next().await != Some(true) {} // let's wait for it to have synced
    println!("123");

    tokio::spawn(async move {
        let mut rx = another_syncer.get_emoji_verification_event_rx().expect("another should get event listener");
        loop {
            match rx.try_next() {
                Ok(Some(event)) => {
                    println!("another: {}", event.get_event_name());
                    match event.get_event_name().as_str() {
                        "AnyToDeviceEvent::KeyVerificationRequest" => {}
                        "AnyToDeviceEvent::KeyVerificationReady" => {}
                        "AnyToDeviceEvent::KeyVerificationStart" => {}
                        "AnyToDeviceEvent::KeyVerificationCancel" => {
                            break;
                        }
                        "AnyToDeviceEvent::KeyVerificationAccept" => {}
                        "AnyToDeviceEvent::KeyVerificationKey" => {}
                        "AnyToDeviceEvent::KeyVerificationMac" => {}
                        "AnyToDeviceEvent::KeyVerificationDone" => {
                            break;
                        }
                        _ => {}
                    }
                }
                Ok(None) => {}
                Err(e) => {}
            }
        }
    });

    println!("123");
    let user_id = another.user_id().await.expect("another should get user id");
    println!("user_id: {:?}", user_id);
    let another_device = another.encryption().get_device(&user_id, device_id!("ANOTHER_DEVICE")).await?;
    println!("another_device: {:?}", another_device);

    if let Some(device) = another_device {
        println!("456");
        device.verify().await?;
        println!("789");
    }

    Ok(())
}
