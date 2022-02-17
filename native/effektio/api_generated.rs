#[allow(unused)]
pub mod api {
    use core::future::Future;
    use core::mem::ManuallyDrop;
    use core::pin::Pin;
    use core::task::{Context, Poll, RawWaker, RawWakerVTable, Waker};
    use std::sync::Arc;
    use std::ffi::c_void;
    use super::*;

    #[doc=" Try to execute some function, catching any panics and aborting to make sure Rust"]
    #[doc=" doesn't unwind across the FFI boundary."]
    pub fn panic_abort<R>(func: impl FnOnce() -> R + std::panic::UnwindSafe) -> R {
        match std::panic::catch_unwind(func) {
            Ok(res) => res,
            Err(_) => {
                std::process::abort();
            }
        }
    }

    #[inline(always)]
    pub fn assert_send_static<T: Send + 'static>(t: T) -> T {
        t
    }

    pub type Result<T, E = String> = core::result::Result<T, E>;

    #[no_mangle]
    pub unsafe extern "C" fn allocate(size: usize, align: usize) -> *mut u8 {
        let layout = std::alloc::Layout::from_size_align_unchecked(size, align);
        let ptr = std::alloc::alloc(layout);
        if ptr.is_null() {
            std::alloc::handle_alloc_error(layout);
        }
        ptr
    }

    #[no_mangle]
    pub unsafe extern "C" fn deallocate(ptr: *mut u8, size: usize, align: usize) {
        let layout = std::alloc::Layout::from_size_align_unchecked(size, align);
        std::alloc::dealloc(ptr, layout);
    }

    pub struct FfiBuffer<T> {
        addr: usize,
        size: usize,
        alloc: usize,
        phantom: std::marker::PhantomData<T>
    }

    impl<T> FfiBuffer<T> {
        pub fn new(data: Vec<T>) -> FfiBuffer<T> {
            unsafe {
                let (addr, size, alloc) = data.into_raw_parts();
                FfiBuffer {
                    addr: std::mem::transmute(addr),
                    size: size * std::mem::size_of::<T>(),
                    alloc: alloc * std::mem::size_of::<T>(),
                    phantom: Default::default(),
                }
            }
        }
    }

    impl<T> Drop for FfiBuffer<T> {
        fn drop(&mut self) {
            unsafe {
                Vec::from_raw_parts(self.addr as *mut u8, self.size, self.alloc);
            }
        }
    }

    #[no_mangle]
    pub unsafe extern "C" fn __ffi_buffer_address(ptr: *mut c_void) -> *mut c_void {
        let buffer = &*(ptr as *mut FfiBuffer<u8>);
        buffer.addr as _
    }

    #[no_mangle]
    pub unsafe extern "C" fn __ffi_buffer_size(ptr: *mut c_void) -> u32 {
        let buffer = &*(ptr as *mut FfiBuffer<u8>);
        buffer.size as _
    }

    #[no_mangle]
    pub extern "C" fn drop_box_FfiBuffer(_: i64, boxed: i64) {
        panic_abort(move || {
            unsafe { Box::<FfiBuffer<u8>>::from_raw(boxed as *mut _) };
        });
    }

    #[repr(transparent)]
    pub struct FfiIter<T: Send + 'static>(Box<dyn Iterator<Item = T> + Send + 'static>);

    impl<T: Send + 'static> FfiIter<T> {
        pub fn new<I>(iter: I) -> Self
        where
            I: IntoIterator<Item = T>,
            I::IntoIter: Send + 'static,
        {
            Self(Box::new(iter.into_iter()))
        }

        pub fn next(&mut self) -> Option<T> {
            self.0.next()
        }
    }

    #[doc=" Converts a closure into a [`Waker`]."]
    #[doc=""]
    #[doc=" The closure gets called every time the waker is woken."]
    pub fn waker_fn<F: Fn() + Send + Sync + 'static>(f: F) -> Waker {
        let raw = Arc::into_raw(Arc::new(f)) as *const ();
        let vtable = &Helper::<F>::VTABLE;
        unsafe { Waker::from_raw(RawWaker::new(raw, vtable)) }
    }

    struct Helper<F>(F);

    impl<F: Fn() + Send + Sync + 'static> Helper<F> {
        const VTABLE: RawWakerVTable = RawWakerVTable::new(
            Self::clone_waker,
            Self::wake,
            Self::wake_by_ref,
            Self::drop_waker,
        );

        unsafe fn clone_waker(ptr: *const ()) -> RawWaker {
            let arc = ManuallyDrop::new(Arc::from_raw(ptr as *const F));
            core::mem::forget(arc.clone());
            RawWaker::new(ptr, &Self::VTABLE)
        }

        unsafe fn wake(ptr: *const ()) {
            let arc = Arc::from_raw(ptr as *const F);
            (arc)();
        }

        unsafe fn wake_by_ref(ptr: *const ()) {
            let arc = ManuallyDrop::new(Arc::from_raw(ptr as *const F));
            (arc)();
        }

        unsafe fn drop_waker(ptr: *const ()) {
            drop(Arc::from_raw(ptr as *const F));
        }
    }

    fn ffi_waker(_post_cobject: isize, port: i64) -> Waker {
        waker_fn(move || unsafe {
            if cfg!(target_family = "wasm") {
                extern "C" {
                    fn __notifier_callback(idx: i32);
                }
                __notifier_callback(port as _);
            } else {
                let post_cobject: extern "C" fn(i64, *const core::ffi::c_void) =
                    core::mem::transmute(_post_cobject);
                let obj: i32 = 0;
                post_cobject(port, &obj as *const _ as *const _);
            }
        })
    }

    #[repr(transparent)]
    pub struct FfiFuture<T: Send + 'static>(Pin<Box<dyn Future<Output = T> + Send + 'static>>);

    impl<T: Send + 'static> FfiFuture<T> {
        pub fn new(f: impl Future<Output = T> + Send + 'static) -> Self {
            Self(Box::pin(f))
        }

        pub fn poll(&mut self, post_cobject: isize, port: i64) -> Option<T> {
            let waker = ffi_waker(post_cobject, port);
            let mut ctx = Context::from_waker(&waker);
            match Pin::new(&mut self.0).poll(&mut ctx) {
                Poll::Ready(res) => Some(res),
                Poll::Pending => None,
            }
        }
    }

    #[cfg(feature = "test_runner")]
    pub trait Stream {
        type Item;

        fn poll_next(self: Pin<&mut Self>, cx: &mut Context) -> Poll<Option<Self::Item>>;
    }

    #[cfg(feature = "test_runner")]
    impl<T> Stream for Pin<T>
    where
        T: core::ops::DerefMut + Unpin,
        T::Target: Stream,
    {
        type Item = <T::Target as Stream>::Item;

        fn poll_next(self: Pin<&mut Self>, cx: &mut Context) -> Poll<Option<Self::Item>> {
            self.get_mut().as_mut().poll_next(cx)
        }
    }

    #[repr(transparent)]
    pub struct FfiStream<T: Send + 'static>(Pin<Box<dyn Stream<Item = T> + Send + 'static>>);

    impl<T: Send + 'static> FfiStream<T> {
        pub fn new(f: impl Stream<Item = T> + Send + 'static) -> Self {
            Self(Box::pin(f))
        }

        pub fn poll(&mut self, post_cobject: isize, port: i64, done: i64) -> Option<T> {
            let waker = ffi_waker(post_cobject, port);
            let mut ctx = Context::from_waker(&waker);
            match Pin::new(&mut self.0).poll_next(&mut ctx) {
                Poll::Ready(Some(res)) => {
                    ffi_waker(post_cobject, port).wake();
                    Some(res)
                }
                Poll::Ready(None) => {
                    ffi_waker(post_cobject, done).wake();
                    None
                }
                Poll::Pending => None,
            }
        }
    }

    #[no_mangle]
    pub extern "C" fn __init_logging(tmp1: u8,tmp3: i64,tmp4: u64,tmp5: u64,) -> __init_loggingReturn {
        panic_abort(move || {
            let tmp0 = if tmp1 == 0 {
                None
            } else {
                let tmp2 = unsafe {
                    String::from_raw_parts(
                        tmp3 as _,
                        tmp4 as _,
                        tmp5 as _,
                    )
                };
                Some(tmp2)
            };let tmp6 = init_logging(tmp0,);#[allow(unused_assignments)] let mut tmp7 = Default::default();#[allow(unused_assignments)] let mut tmp10 = Default::default();#[allow(unused_assignments)] let mut tmp11 = Default::default();#[allow(unused_assignments)] let mut tmp12 = Default::default();match tmp6 {
                Ok(tmp8) => {
                    tmp7 = 1;
                }
                Err(tmp9_0) => {
                    tmp7 = 0;
                    let tmp9 = tmp9_0.to_string();
                    let tmp9_0 = ManuallyDrop::new(tmp9);
                    tmp10 = tmp9_0.as_ptr() as _;
                    tmp11 = tmp9_0.len() as _;
                    tmp12 = tmp9_0.capacity() as _;
                }
            };
            __init_loggingReturn {
                ret0: tmp7,ret1: tmp10,ret2: tmp11,ret3: tmp12,
            }
        })
    }
    #[repr(C)]
    pub struct __init_loggingReturn {
        pub ret0: u8,pub ret1: i64,pub ret2: u64,pub ret3: u64,
    }#[no_mangle]
    pub extern "C" fn __login_new_client(tmp1: i64,tmp2: u64,tmp3: u64,tmp5: i64,tmp6: u64,tmp7: u64,tmp9: i64,tmp10: u64,tmp11: u64,) -> i64 {
        panic_abort(move || {
            let tmp0 = unsafe {
                String::from_raw_parts(
                    tmp1 as _,
                    tmp2 as _,
                    tmp3 as _,
                )
            };let tmp4 = unsafe {
                String::from_raw_parts(
                    tmp5 as _,
                    tmp6 as _,
                    tmp7 as _,
                )
            };let tmp8 = unsafe {
                String::from_raw_parts(
                    tmp9 as _,
                    tmp10 as _,
                    tmp11 as _,
                )
            };let tmp12 = login_new_client(tmp0,tmp4,tmp8,);#[allow(unused_assignments)] let mut tmp13 = Default::default();let tmp13_0 = async move { tmp12.await.map_err(|err| err.to_string()) };
            let tmp13_1: FfiFuture<Result<Client>> = FfiFuture::new(tmp13_0);
            tmp13 = Box::into_raw(Box::new(tmp13_1)) as _;
            tmp13
        })
    }
    #[no_mangle]
    pub extern "C" fn __login_with_token(tmp1: i64,tmp2: u64,tmp3: u64,tmp5: i64,tmp6: u64,tmp7: u64,) -> i64 {
        panic_abort(move || {
            let tmp0 = unsafe {
                String::from_raw_parts(
                    tmp1 as _,
                    tmp2 as _,
                    tmp3 as _,
                )
            };let tmp4 = unsafe {
                String::from_raw_parts(
                    tmp5 as _,
                    tmp6 as _,
                    tmp7 as _,
                )
            };let tmp8 = login_with_token(tmp0,tmp4,);#[allow(unused_assignments)] let mut tmp9 = Default::default();let tmp9_0 = async move { tmp8.await.map_err(|err| err.to_string()) };
            let tmp9_1: FfiFuture<Result<Client>> = FfiFuture::new(tmp9_0);
            tmp9 = Box::into_raw(Box::new(tmp9_1)) as _;
            tmp9
        })
    }
    #[no_mangle]
    pub extern "C" fn __guest_client(tmp1: i64,tmp2: u64,tmp3: u64,tmp5: i64,tmp6: u64,tmp7: u64,) -> i64 {
        panic_abort(move || {
            let tmp0 = unsafe {
                String::from_raw_parts(
                    tmp1 as _,
                    tmp2 as _,
                    tmp3 as _,
                )
            };let tmp4 = unsafe {
                String::from_raw_parts(
                    tmp5 as _,
                    tmp6 as _,
                    tmp7 as _,
                )
            };let tmp8 = guest_client(tmp0,tmp4,);#[allow(unused_assignments)] let mut tmp9 = Default::default();let tmp9_0 = async move { tmp8.await.map_err(|err| err.to_string()) };
            let tmp9_1: FfiFuture<Result<Client>> = FfiFuture::new(tmp9_0);
            tmp9 = Box::into_raw(Box::new(tmp9_1)) as _;
            tmp9
        })
    }
    #[no_mangle]
    pub extern "C" fn __Room_display_name(tmp1: i64,) -> i64 {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut Room) };let tmp2 = tmp0.display_name();#[allow(unused_assignments)] let mut tmp3 = Default::default();let tmp3_0 = async move { tmp2.await.map_err(|err| err.to_string()) };
            let tmp3_1: FfiFuture<Result<String>> = FfiFuture::new(tmp3_0);
            tmp3 = Box::into_raw(Box::new(tmp3_1)) as _;
            tmp3
        })
    }
    #[no_mangle]
    pub extern "C" fn __Room_avatar(tmp1: i64,) -> i64 {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut Room) };let tmp2 = tmp0.avatar();#[allow(unused_assignments)] let mut tmp3 = Default::default();let tmp3_0 = async move { tmp2.await.map_err(|err| err.to_string()) };
            let tmp3_1: FfiFuture<Result<FfiBuffer<u8>>> = FfiFuture::new(tmp3_0);
            tmp3 = Box::into_raw(Box::new(tmp3_1)) as _;
            tmp3
        })
    }
    #[no_mangle]
    pub extern "C" fn drop_box_Room(_: i64, boxed: i64) {
        panic_abort(move || {
            unsafe { Box::<Room>::from_raw(boxed as *mut _) };
        });
    }#[no_mangle]
    pub extern "C" fn __Client_restore_token(tmp1: i64,) -> i64 {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut Client) };let tmp2 = tmp0.restore_token();#[allow(unused_assignments)] let mut tmp3 = Default::default();let tmp3_0 = async move { tmp2.await.map_err(|err| err.to_string()) };
            let tmp3_1: FfiFuture<Result<String>> = FfiFuture::new(tmp3_0);
            tmp3 = Box::into_raw(Box::new(tmp3_1)) as _;
            tmp3
        })
    }
    #[no_mangle]
    pub extern "C" fn __Client_is_guest(tmp1: i64,) -> u8 {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut Client) };let tmp2 = tmp0.is_guest();#[allow(unused_assignments)] let mut tmp3 = Default::default();tmp3 = if tmp2 { 1 } else { 0 };
            tmp3
        })
    }
    #[no_mangle]
    pub extern "C" fn __Client_has_first_synced(tmp1: i64,) -> u8 {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut Client) };let tmp2 = tmp0.has_first_synced();#[allow(unused_assignments)] let mut tmp3 = Default::default();tmp3 = if tmp2 { 1 } else { 0 };
            tmp3
        })
    }
    #[no_mangle]
    pub extern "C" fn __Client_is_syncing(tmp1: i64,) -> u8 {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut Client) };let tmp2 = tmp0.is_syncing();#[allow(unused_assignments)] let mut tmp3 = Default::default();tmp3 = if tmp2 { 1 } else { 0 };
            tmp3
        })
    }
    #[no_mangle]
    pub extern "C" fn __Client_logged_in(tmp1: i64,) -> i64 {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut Client) };let tmp2 = tmp0.logged_in();#[allow(unused_assignments)] let mut tmp3 = Default::default();let tmp3_0 = tmp2;
            let tmp3_1: FfiFuture<bool> = FfiFuture::new(tmp3_0);
            tmp3 = Box::into_raw(Box::new(tmp3_1)) as _;
            tmp3
        })
    }
    #[no_mangle]
    pub extern "C" fn __Client_user_id(tmp1: i64,) -> i64 {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut Client) };let tmp2 = tmp0.user_id();#[allow(unused_assignments)] let mut tmp3 = Default::default();let tmp3_0 = async move { tmp2.await.map_err(|err| err.to_string()) };
            let tmp3_1: FfiFuture<Result<String>> = FfiFuture::new(tmp3_0);
            tmp3 = Box::into_raw(Box::new(tmp3_1)) as _;
            tmp3
        })
    }
    #[no_mangle]
    pub extern "C" fn __Client_device_id(tmp1: i64,) -> i64 {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut Client) };let tmp2 = tmp0.device_id();#[allow(unused_assignments)] let mut tmp3 = Default::default();let tmp3_0 = async move { tmp2.await.map_err(|err| err.to_string()) };
            let tmp3_1: FfiFuture<Result<String>> = FfiFuture::new(tmp3_0);
            tmp3 = Box::into_raw(Box::new(tmp3_1)) as _;
            tmp3
        })
    }
    #[no_mangle]
    pub extern "C" fn __Client_display_name(tmp1: i64,) -> i64 {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut Client) };let tmp2 = tmp0.display_name();#[allow(unused_assignments)] let mut tmp3 = Default::default();let tmp3_0 = async move { tmp2.await.map_err(|err| err.to_string()) };
            let tmp3_1: FfiFuture<Result<String>> = FfiFuture::new(tmp3_0);
            tmp3 = Box::into_raw(Box::new(tmp3_1)) as _;
            tmp3
        })
    }
    #[no_mangle]
    pub extern "C" fn __Client_avatar(tmp1: i64,) -> i64 {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut Client) };let tmp2 = tmp0.avatar();#[allow(unused_assignments)] let mut tmp3 = Default::default();let tmp3_0 = async move { tmp2.await.map_err(|err| err.to_string()) };
            let tmp3_1: FfiFuture<Result<FfiBuffer<u8>>> = FfiFuture::new(tmp3_0);
            tmp3 = Box::into_raw(Box::new(tmp3_1)) as _;
            tmp3
        })
    }
    #[no_mangle]
    pub extern "C" fn __Client_conversations(tmp1: i64,) -> i64 {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut Client) };let tmp2 = tmp0.conversations();#[allow(unused_assignments)] let mut tmp3 = Default::default();let tmp3_0: FfiStream<Room> = FfiStream::new(tmp2);
            tmp3 = Box::into_raw(Box::new(tmp3_0)) as _;
            tmp3
        })
    }
    #[no_mangle]
    pub extern "C" fn drop_box_Client(_: i64, boxed: i64) {
        panic_abort(move || {
            unsafe { Box::<Client>::from_raw(boxed as *mut _) };
        });
    }
    #[no_mangle]
    pub extern "C" fn __login_new_client_future_poll(tmp1: i64,tmp3: i64,tmp5: i64,) -> __login_new_client_future_pollReturn {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut FfiFuture<Result<Client>>) };let tmp2 = tmp3 as _;let tmp4 = tmp5 as _;let tmp6 = tmp0.poll(tmp2,tmp4,);#[allow(unused_assignments)] let mut tmp7 = Default::default();#[allow(unused_assignments)] let mut tmp9 = Default::default();#[allow(unused_assignments)] let mut tmp12 = Default::default();#[allow(unused_assignments)] let mut tmp13 = Default::default();#[allow(unused_assignments)] let mut tmp14 = Default::default();#[allow(unused_assignments)] let mut tmp15 = Default::default();if let Some(tmp8) = tmp6 {
                tmp7 = 1;
                match tmp8 {
                    Ok(tmp10) => {
                        tmp9 = 1;
                        let tmp10_0 = assert_send_static(tmp10);
                        tmp15 = Box::into_raw(Box::new(tmp10_0)) as _;
                    }
                    Err(tmp11_0) => {
                        tmp9 = 0;
                        let tmp11 = tmp11_0.to_string();
                        let tmp11_0 = ManuallyDrop::new(tmp11);
                        tmp12 = tmp11_0.as_ptr() as _;
                        tmp13 = tmp11_0.len() as _;
                        tmp14 = tmp11_0.capacity() as _;
                    }
                };
            } else {
                tmp7 = 0;
            }
            __login_new_client_future_pollReturn {
                ret0: tmp7,ret1: tmp9,ret2: tmp12,ret3: tmp13,ret4: tmp14,ret5: tmp15,
            }
        })
    }
    #[repr(C)]
    pub struct __login_new_client_future_pollReturn {
        pub ret0: u8,pub ret1: u8,pub ret2: i64,pub ret3: u64,pub ret4: u64,pub ret5: i64,
    }
    #[no_mangle]
    pub extern "C" fn __login_new_client_future_drop(_: i64, boxed: i64) {
        panic_abort(move || {
            unsafe { Box::<FfiFuture<Result<Client>>>::from_raw(boxed as *mut _) };
        });
    }#[no_mangle]
    pub extern "C" fn __login_with_token_future_poll(tmp1: i64,tmp3: i64,tmp5: i64,) -> __login_with_token_future_pollReturn {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut FfiFuture<Result<Client>>) };let tmp2 = tmp3 as _;let tmp4 = tmp5 as _;let tmp6 = tmp0.poll(tmp2,tmp4,);#[allow(unused_assignments)] let mut tmp7 = Default::default();#[allow(unused_assignments)] let mut tmp9 = Default::default();#[allow(unused_assignments)] let mut tmp12 = Default::default();#[allow(unused_assignments)] let mut tmp13 = Default::default();#[allow(unused_assignments)] let mut tmp14 = Default::default();#[allow(unused_assignments)] let mut tmp15 = Default::default();if let Some(tmp8) = tmp6 {
                tmp7 = 1;
                match tmp8 {
                    Ok(tmp10) => {
                        tmp9 = 1;
                        let tmp10_0 = assert_send_static(tmp10);
                        tmp15 = Box::into_raw(Box::new(tmp10_0)) as _;
                    }
                    Err(tmp11_0) => {
                        tmp9 = 0;
                        let tmp11 = tmp11_0.to_string();
                        let tmp11_0 = ManuallyDrop::new(tmp11);
                        tmp12 = tmp11_0.as_ptr() as _;
                        tmp13 = tmp11_0.len() as _;
                        tmp14 = tmp11_0.capacity() as _;
                    }
                };
            } else {
                tmp7 = 0;
            }
            __login_with_token_future_pollReturn {
                ret0: tmp7,ret1: tmp9,ret2: tmp12,ret3: tmp13,ret4: tmp14,ret5: tmp15,
            }
        })
    }
    #[repr(C)]
    pub struct __login_with_token_future_pollReturn {
        pub ret0: u8,pub ret1: u8,pub ret2: i64,pub ret3: u64,pub ret4: u64,pub ret5: i64,
    }
    #[no_mangle]
    pub extern "C" fn __login_with_token_future_drop(_: i64, boxed: i64) {
        panic_abort(move || {
            unsafe { Box::<FfiFuture<Result<Client>>>::from_raw(boxed as *mut _) };
        });
    }#[no_mangle]
    pub extern "C" fn __guest_client_future_poll(tmp1: i64,tmp3: i64,tmp5: i64,) -> __guest_client_future_pollReturn {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut FfiFuture<Result<Client>>) };let tmp2 = tmp3 as _;let tmp4 = tmp5 as _;let tmp6 = tmp0.poll(tmp2,tmp4,);#[allow(unused_assignments)] let mut tmp7 = Default::default();#[allow(unused_assignments)] let mut tmp9 = Default::default();#[allow(unused_assignments)] let mut tmp12 = Default::default();#[allow(unused_assignments)] let mut tmp13 = Default::default();#[allow(unused_assignments)] let mut tmp14 = Default::default();#[allow(unused_assignments)] let mut tmp15 = Default::default();if let Some(tmp8) = tmp6 {
                tmp7 = 1;
                match tmp8 {
                    Ok(tmp10) => {
                        tmp9 = 1;
                        let tmp10_0 = assert_send_static(tmp10);
                        tmp15 = Box::into_raw(Box::new(tmp10_0)) as _;
                    }
                    Err(tmp11_0) => {
                        tmp9 = 0;
                        let tmp11 = tmp11_0.to_string();
                        let tmp11_0 = ManuallyDrop::new(tmp11);
                        tmp12 = tmp11_0.as_ptr() as _;
                        tmp13 = tmp11_0.len() as _;
                        tmp14 = tmp11_0.capacity() as _;
                    }
                };
            } else {
                tmp7 = 0;
            }
            __guest_client_future_pollReturn {
                ret0: tmp7,ret1: tmp9,ret2: tmp12,ret3: tmp13,ret4: tmp14,ret5: tmp15,
            }
        })
    }
    #[repr(C)]
    pub struct __guest_client_future_pollReturn {
        pub ret0: u8,pub ret1: u8,pub ret2: i64,pub ret3: u64,pub ret4: u64,pub ret5: i64,
    }
    #[no_mangle]
    pub extern "C" fn __guest_client_future_drop(_: i64, boxed: i64) {
        panic_abort(move || {
            unsafe { Box::<FfiFuture<Result<Client>>>::from_raw(boxed as *mut _) };
        });
    }#[no_mangle]
    pub extern "C" fn __Room_display_name_future_poll(tmp1: i64,tmp3: i64,tmp5: i64,) -> __Room_display_name_future_pollReturn {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut FfiFuture<Result<String>>) };let tmp2 = tmp3 as _;let tmp4 = tmp5 as _;let tmp6 = tmp0.poll(tmp2,tmp4,);#[allow(unused_assignments)] let mut tmp7 = Default::default();#[allow(unused_assignments)] let mut tmp9 = Default::default();#[allow(unused_assignments)] let mut tmp12 = Default::default();#[allow(unused_assignments)] let mut tmp13 = Default::default();#[allow(unused_assignments)] let mut tmp14 = Default::default();#[allow(unused_assignments)] let mut tmp15 = Default::default();#[allow(unused_assignments)] let mut tmp16 = Default::default();#[allow(unused_assignments)] let mut tmp17 = Default::default();if let Some(tmp8) = tmp6 {
                tmp7 = 1;
                match tmp8 {
                    Ok(tmp10) => {
                        tmp9 = 1;
                        let tmp10_0 = ManuallyDrop::new(tmp10);
                        tmp15 = tmp10_0.as_ptr() as _;
                        tmp16 = tmp10_0.len() as _;
                        tmp17 = tmp10_0.capacity() as _;
                    }
                    Err(tmp11_0) => {
                        tmp9 = 0;
                        let tmp11 = tmp11_0.to_string();
                        let tmp11_0 = ManuallyDrop::new(tmp11);
                        tmp12 = tmp11_0.as_ptr() as _;
                        tmp13 = tmp11_0.len() as _;
                        tmp14 = tmp11_0.capacity() as _;
                    }
                };
            } else {
                tmp7 = 0;
            }
            __Room_display_name_future_pollReturn {
                ret0: tmp7,ret1: tmp9,ret2: tmp12,ret3: tmp13,ret4: tmp14,ret5: tmp15,ret6: tmp16,ret7: tmp17,
            }
        })
    }
    #[repr(C)]
    pub struct __Room_display_name_future_pollReturn {
        pub ret0: u8,pub ret1: u8,pub ret2: i64,pub ret3: u64,pub ret4: u64,pub ret5: i64,pub ret6: u64,pub ret7: u64,
    }
    #[no_mangle]
    pub extern "C" fn __Room_display_name_future_drop(_: i64, boxed: i64) {
        panic_abort(move || {
            unsafe { Box::<FfiFuture<Result<String>>>::from_raw(boxed as *mut _) };
        });
    }#[no_mangle]
    pub extern "C" fn __Room_avatar_future_poll(tmp1: i64,tmp3: i64,tmp5: i64,) -> __Room_avatar_future_pollReturn {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut FfiFuture<Result<FfiBuffer<u8>>>) };let tmp2 = tmp3 as _;let tmp4 = tmp5 as _;let tmp6 = tmp0.poll(tmp2,tmp4,);#[allow(unused_assignments)] let mut tmp7 = Default::default();#[allow(unused_assignments)] let mut tmp9 = Default::default();#[allow(unused_assignments)] let mut tmp12 = Default::default();#[allow(unused_assignments)] let mut tmp13 = Default::default();#[allow(unused_assignments)] let mut tmp14 = Default::default();#[allow(unused_assignments)] let mut tmp15 = Default::default();if let Some(tmp8) = tmp6 {
                tmp7 = 1;
                match tmp8 {
                    Ok(tmp10) => {
                        tmp9 = 1;
                        let tmp10_0 = assert_send_static(tmp10);
                        tmp15 = Box::into_raw(Box::new(tmp10_0)) as _;
                    }
                    Err(tmp11_0) => {
                        tmp9 = 0;
                        let tmp11 = tmp11_0.to_string();
                        let tmp11_0 = ManuallyDrop::new(tmp11);
                        tmp12 = tmp11_0.as_ptr() as _;
                        tmp13 = tmp11_0.len() as _;
                        tmp14 = tmp11_0.capacity() as _;
                    }
                };
            } else {
                tmp7 = 0;
            }
            __Room_avatar_future_pollReturn {
                ret0: tmp7,ret1: tmp9,ret2: tmp12,ret3: tmp13,ret4: tmp14,ret5: tmp15,
            }
        })
    }
    #[repr(C)]
    pub struct __Room_avatar_future_pollReturn {
        pub ret0: u8,pub ret1: u8,pub ret2: i64,pub ret3: u64,pub ret4: u64,pub ret5: i64,
    }
    #[no_mangle]
    pub extern "C" fn __Room_avatar_future_drop(_: i64, boxed: i64) {
        panic_abort(move || {
            unsafe { Box::<FfiFuture<Result<FfiBuffer<u8>>>>::from_raw(boxed as *mut _) };
        });
    }#[no_mangle]
    pub extern "C" fn __Client_restore_token_future_poll(tmp1: i64,tmp3: i64,tmp5: i64,) -> __Client_restore_token_future_pollReturn {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut FfiFuture<Result<String>>) };let tmp2 = tmp3 as _;let tmp4 = tmp5 as _;let tmp6 = tmp0.poll(tmp2,tmp4,);#[allow(unused_assignments)] let mut tmp7 = Default::default();#[allow(unused_assignments)] let mut tmp9 = Default::default();#[allow(unused_assignments)] let mut tmp12 = Default::default();#[allow(unused_assignments)] let mut tmp13 = Default::default();#[allow(unused_assignments)] let mut tmp14 = Default::default();#[allow(unused_assignments)] let mut tmp15 = Default::default();#[allow(unused_assignments)] let mut tmp16 = Default::default();#[allow(unused_assignments)] let mut tmp17 = Default::default();if let Some(tmp8) = tmp6 {
                tmp7 = 1;
                match tmp8 {
                    Ok(tmp10) => {
                        tmp9 = 1;
                        let tmp10_0 = ManuallyDrop::new(tmp10);
                        tmp15 = tmp10_0.as_ptr() as _;
                        tmp16 = tmp10_0.len() as _;
                        tmp17 = tmp10_0.capacity() as _;
                    }
                    Err(tmp11_0) => {
                        tmp9 = 0;
                        let tmp11 = tmp11_0.to_string();
                        let tmp11_0 = ManuallyDrop::new(tmp11);
                        tmp12 = tmp11_0.as_ptr() as _;
                        tmp13 = tmp11_0.len() as _;
                        tmp14 = tmp11_0.capacity() as _;
                    }
                };
            } else {
                tmp7 = 0;
            }
            __Client_restore_token_future_pollReturn {
                ret0: tmp7,ret1: tmp9,ret2: tmp12,ret3: tmp13,ret4: tmp14,ret5: tmp15,ret6: tmp16,ret7: tmp17,
            }
        })
    }
    #[repr(C)]
    pub struct __Client_restore_token_future_pollReturn {
        pub ret0: u8,pub ret1: u8,pub ret2: i64,pub ret3: u64,pub ret4: u64,pub ret5: i64,pub ret6: u64,pub ret7: u64,
    }
    #[no_mangle]
    pub extern "C" fn __Client_restore_token_future_drop(_: i64, boxed: i64) {
        panic_abort(move || {
            unsafe { Box::<FfiFuture<Result<String>>>::from_raw(boxed as *mut _) };
        });
    }#[no_mangle]
    pub extern "C" fn __Client_logged_in_future_poll(tmp1: i64,tmp3: i64,tmp5: i64,) -> __Client_logged_in_future_pollReturn {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut FfiFuture<bool>) };let tmp2 = tmp3 as _;let tmp4 = tmp5 as _;let tmp6 = tmp0.poll(tmp2,tmp4,);#[allow(unused_assignments)] let mut tmp7 = Default::default();#[allow(unused_assignments)] let mut tmp9 = Default::default();if let Some(tmp8) = tmp6 {
                tmp7 = 1;
                tmp9 = if tmp8 { 1 } else { 0 };
            } else {
                tmp7 = 0;
            }
            __Client_logged_in_future_pollReturn {
                ret0: tmp7,ret1: tmp9,
            }
        })
    }
    #[repr(C)]
    pub struct __Client_logged_in_future_pollReturn {
        pub ret0: u8,pub ret1: u8,
    }
    #[no_mangle]
    pub extern "C" fn __Client_logged_in_future_drop(_: i64, boxed: i64) {
        panic_abort(move || {
            unsafe { Box::<FfiFuture<bool>>::from_raw(boxed as *mut _) };
        });
    }#[no_mangle]
    pub extern "C" fn __Client_user_id_future_poll(tmp1: i64,tmp3: i64,tmp5: i64,) -> __Client_user_id_future_pollReturn {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut FfiFuture<Result<String>>) };let tmp2 = tmp3 as _;let tmp4 = tmp5 as _;let tmp6 = tmp0.poll(tmp2,tmp4,);#[allow(unused_assignments)] let mut tmp7 = Default::default();#[allow(unused_assignments)] let mut tmp9 = Default::default();#[allow(unused_assignments)] let mut tmp12 = Default::default();#[allow(unused_assignments)] let mut tmp13 = Default::default();#[allow(unused_assignments)] let mut tmp14 = Default::default();#[allow(unused_assignments)] let mut tmp15 = Default::default();#[allow(unused_assignments)] let mut tmp16 = Default::default();#[allow(unused_assignments)] let mut tmp17 = Default::default();if let Some(tmp8) = tmp6 {
                tmp7 = 1;
                match tmp8 {
                    Ok(tmp10) => {
                        tmp9 = 1;
                        let tmp10_0 = ManuallyDrop::new(tmp10);
                        tmp15 = tmp10_0.as_ptr() as _;
                        tmp16 = tmp10_0.len() as _;
                        tmp17 = tmp10_0.capacity() as _;
                    }
                    Err(tmp11_0) => {
                        tmp9 = 0;
                        let tmp11 = tmp11_0.to_string();
                        let tmp11_0 = ManuallyDrop::new(tmp11);
                        tmp12 = tmp11_0.as_ptr() as _;
                        tmp13 = tmp11_0.len() as _;
                        tmp14 = tmp11_0.capacity() as _;
                    }
                };
            } else {
                tmp7 = 0;
            }
            __Client_user_id_future_pollReturn {
                ret0: tmp7,ret1: tmp9,ret2: tmp12,ret3: tmp13,ret4: tmp14,ret5: tmp15,ret6: tmp16,ret7: tmp17,
            }
        })
    }
    #[repr(C)]
    pub struct __Client_user_id_future_pollReturn {
        pub ret0: u8,pub ret1: u8,pub ret2: i64,pub ret3: u64,pub ret4: u64,pub ret5: i64,pub ret6: u64,pub ret7: u64,
    }
    #[no_mangle]
    pub extern "C" fn __Client_user_id_future_drop(_: i64, boxed: i64) {
        panic_abort(move || {
            unsafe { Box::<FfiFuture<Result<String>>>::from_raw(boxed as *mut _) };
        });
    }#[no_mangle]
    pub extern "C" fn __Client_device_id_future_poll(tmp1: i64,tmp3: i64,tmp5: i64,) -> __Client_device_id_future_pollReturn {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut FfiFuture<Result<String>>) };let tmp2 = tmp3 as _;let tmp4 = tmp5 as _;let tmp6 = tmp0.poll(tmp2,tmp4,);#[allow(unused_assignments)] let mut tmp7 = Default::default();#[allow(unused_assignments)] let mut tmp9 = Default::default();#[allow(unused_assignments)] let mut tmp12 = Default::default();#[allow(unused_assignments)] let mut tmp13 = Default::default();#[allow(unused_assignments)] let mut tmp14 = Default::default();#[allow(unused_assignments)] let mut tmp15 = Default::default();#[allow(unused_assignments)] let mut tmp16 = Default::default();#[allow(unused_assignments)] let mut tmp17 = Default::default();if let Some(tmp8) = tmp6 {
                tmp7 = 1;
                match tmp8 {
                    Ok(tmp10) => {
                        tmp9 = 1;
                        let tmp10_0 = ManuallyDrop::new(tmp10);
                        tmp15 = tmp10_0.as_ptr() as _;
                        tmp16 = tmp10_0.len() as _;
                        tmp17 = tmp10_0.capacity() as _;
                    }
                    Err(tmp11_0) => {
                        tmp9 = 0;
                        let tmp11 = tmp11_0.to_string();
                        let tmp11_0 = ManuallyDrop::new(tmp11);
                        tmp12 = tmp11_0.as_ptr() as _;
                        tmp13 = tmp11_0.len() as _;
                        tmp14 = tmp11_0.capacity() as _;
                    }
                };
            } else {
                tmp7 = 0;
            }
            __Client_device_id_future_pollReturn {
                ret0: tmp7,ret1: tmp9,ret2: tmp12,ret3: tmp13,ret4: tmp14,ret5: tmp15,ret6: tmp16,ret7: tmp17,
            }
        })
    }
    #[repr(C)]
    pub struct __Client_device_id_future_pollReturn {
        pub ret0: u8,pub ret1: u8,pub ret2: i64,pub ret3: u64,pub ret4: u64,pub ret5: i64,pub ret6: u64,pub ret7: u64,
    }
    #[no_mangle]
    pub extern "C" fn __Client_device_id_future_drop(_: i64, boxed: i64) {
        panic_abort(move || {
            unsafe { Box::<FfiFuture<Result<String>>>::from_raw(boxed as *mut _) };
        });
    }#[no_mangle]
    pub extern "C" fn __Client_display_name_future_poll(tmp1: i64,tmp3: i64,tmp5: i64,) -> __Client_display_name_future_pollReturn {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut FfiFuture<Result<String>>) };let tmp2 = tmp3 as _;let tmp4 = tmp5 as _;let tmp6 = tmp0.poll(tmp2,tmp4,);#[allow(unused_assignments)] let mut tmp7 = Default::default();#[allow(unused_assignments)] let mut tmp9 = Default::default();#[allow(unused_assignments)] let mut tmp12 = Default::default();#[allow(unused_assignments)] let mut tmp13 = Default::default();#[allow(unused_assignments)] let mut tmp14 = Default::default();#[allow(unused_assignments)] let mut tmp15 = Default::default();#[allow(unused_assignments)] let mut tmp16 = Default::default();#[allow(unused_assignments)] let mut tmp17 = Default::default();if let Some(tmp8) = tmp6 {
                tmp7 = 1;
                match tmp8 {
                    Ok(tmp10) => {
                        tmp9 = 1;
                        let tmp10_0 = ManuallyDrop::new(tmp10);
                        tmp15 = tmp10_0.as_ptr() as _;
                        tmp16 = tmp10_0.len() as _;
                        tmp17 = tmp10_0.capacity() as _;
                    }
                    Err(tmp11_0) => {
                        tmp9 = 0;
                        let tmp11 = tmp11_0.to_string();
                        let tmp11_0 = ManuallyDrop::new(tmp11);
                        tmp12 = tmp11_0.as_ptr() as _;
                        tmp13 = tmp11_0.len() as _;
                        tmp14 = tmp11_0.capacity() as _;
                    }
                };
            } else {
                tmp7 = 0;
            }
            __Client_display_name_future_pollReturn {
                ret0: tmp7,ret1: tmp9,ret2: tmp12,ret3: tmp13,ret4: tmp14,ret5: tmp15,ret6: tmp16,ret7: tmp17,
            }
        })
    }
    #[repr(C)]
    pub struct __Client_display_name_future_pollReturn {
        pub ret0: u8,pub ret1: u8,pub ret2: i64,pub ret3: u64,pub ret4: u64,pub ret5: i64,pub ret6: u64,pub ret7: u64,
    }
    #[no_mangle]
    pub extern "C" fn __Client_display_name_future_drop(_: i64, boxed: i64) {
        panic_abort(move || {
            unsafe { Box::<FfiFuture<Result<String>>>::from_raw(boxed as *mut _) };
        });
    }#[no_mangle]
    pub extern "C" fn __Client_avatar_future_poll(tmp1: i64,tmp3: i64,tmp5: i64,) -> __Client_avatar_future_pollReturn {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut FfiFuture<Result<FfiBuffer<u8>>>) };let tmp2 = tmp3 as _;let tmp4 = tmp5 as _;let tmp6 = tmp0.poll(tmp2,tmp4,);#[allow(unused_assignments)] let mut tmp7 = Default::default();#[allow(unused_assignments)] let mut tmp9 = Default::default();#[allow(unused_assignments)] let mut tmp12 = Default::default();#[allow(unused_assignments)] let mut tmp13 = Default::default();#[allow(unused_assignments)] let mut tmp14 = Default::default();#[allow(unused_assignments)] let mut tmp15 = Default::default();if let Some(tmp8) = tmp6 {
                tmp7 = 1;
                match tmp8 {
                    Ok(tmp10) => {
                        tmp9 = 1;
                        let tmp10_0 = assert_send_static(tmp10);
                        tmp15 = Box::into_raw(Box::new(tmp10_0)) as _;
                    }
                    Err(tmp11_0) => {
                        tmp9 = 0;
                        let tmp11 = tmp11_0.to_string();
                        let tmp11_0 = ManuallyDrop::new(tmp11);
                        tmp12 = tmp11_0.as_ptr() as _;
                        tmp13 = tmp11_0.len() as _;
                        tmp14 = tmp11_0.capacity() as _;
                    }
                };
            } else {
                tmp7 = 0;
            }
            __Client_avatar_future_pollReturn {
                ret0: tmp7,ret1: tmp9,ret2: tmp12,ret3: tmp13,ret4: tmp14,ret5: tmp15,
            }
        })
    }
    #[repr(C)]
    pub struct __Client_avatar_future_pollReturn {
        pub ret0: u8,pub ret1: u8,pub ret2: i64,pub ret3: u64,pub ret4: u64,pub ret5: i64,
    }
    #[no_mangle]
    pub extern "C" fn __Client_avatar_future_drop(_: i64, boxed: i64) {
        panic_abort(move || {
            unsafe { Box::<FfiFuture<Result<FfiBuffer<u8>>>>::from_raw(boxed as *mut _) };
        });
    }
    #[no_mangle]
    pub extern "C" fn __Client_conversations_stream_poll(tmp1: i64,tmp3: i64,tmp5: i64,tmp7: i64,) -> __Client_conversations_stream_pollReturn {
        panic_abort(move || {
            let tmp0 = unsafe { &mut *(tmp1 as *mut FfiStream<Room>) };let tmp2 = tmp3 as _;let tmp4 = tmp5 as _;let tmp6 = tmp7 as _;let tmp8 = tmp0.poll(tmp2,tmp4,tmp6,);#[allow(unused_assignments)] let mut tmp9 = Default::default();#[allow(unused_assignments)] let mut tmp11 = Default::default();if let Some(tmp10) = tmp8 {
                tmp9 = 1;
                let tmp10_0 = assert_send_static(tmp10);
                tmp11 = Box::into_raw(Box::new(tmp10_0)) as _;
            } else {
                tmp9 = 0;
            }
            __Client_conversations_stream_pollReturn {
                ret0: tmp9,ret1: tmp11,
            }
        })
    }
    #[repr(C)]
    pub struct __Client_conversations_stream_pollReturn {
        pub ret0: u8,pub ret1: i64,
    }
    #[no_mangle]
    pub extern "C" fn __Client_conversations_stream_drop(_: i64, boxed: i64) {
        panic_abort(move || {
            unsafe { Box::<FfiStream<Room>>::from_raw(boxed as *mut _) };
        });
    }
}
