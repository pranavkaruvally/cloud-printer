use std::net::SocketAddr;

use http_body_util::Full;
use hyper::body::{Body, Bytes};
use hyper::server::conn::http1;
use hyper::service::service_fn;
use hyper::{Request, Response};
use hyper_util::rt::TokioIo;
use tokio::net::TcpListener;

use hyper::body::Frame;
use hyper::{Method, StatusCode};
use http_body_util::{combinators::BoxBody, BodyExt, Empty};

use std::fs;
use std::io::prelude::*;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let addr = SocketAddr::from(([127, 0, 0, 1], 3000));

    let listener = TcpListener::bind(addr).await?;

    loop {
        let (stream, _) = listener.accept().await?;
        let io = TokioIo::new(stream);
        tokio::task::spawn(async move {
            if let Err(err) = http1::Builder::new()
                .serve_connection(io, service_fn(echo))
                .await
            {
                println!("Error serving connection: {:?}", err);
            }
        });
    }
}

async fn echo(
    req: Request<hyper::body::Incoming>,
) -> Result<Response<BoxBody<Bytes, hyper::Error>>, hyper::Error> {
    let contents: String;
    match (req.method(), req.uri().path()) {
        (&Method::GET, "/") => {
            contents = fs::read_to_string("templates/hello.html").unwrap();
            Ok(Response::new(full(contents)))
    },

        (&Method::GET, "/upload") => {
            contents = fs::read_to_string("templates/upload.html").unwrap();
            Ok(Response::new(full(contents)))
        },

        (&Method::POST, "/echo") => Ok(Response::new(req.into_body().boxed())),

        (&Method::POST, "/print") => {
            _ = parse_multipart(req).await;
            Ok(Response::new(full("Printed...")))
        },

        (&Method::POST, "/echo/uppercase") => {
            let frame_stream = req.into_body().map_frame(|frame| {
                let frame = if let Ok(data) = frame.into_data() {
                    data.iter()
                        .map(|byte| byte.to_ascii_uppercase())
                        .collect::<Bytes>()
                } else {
                    Bytes::new()
                };
                Frame::data(frame)
            });

        Ok(Response::new(frame_stream.boxed()))
        }

        (&Method::POST, "/echo/reversed") => {
            let upper = req.body().size_hint().upper().unwrap_or(u64::MAX);
            if upper > 1024 * 64 {
                let mut resp = Response::new(full("Body too big"));
                *resp.status_mut() = hyper::StatusCode::PAYLOAD_TOO_LARGE;
                return Ok(resp);
            }

            let whole_body = req.collect().await?.to_bytes();
            let reversed_body = whole_body.iter()
                .rev()
                .cloned()
                .collect::<Vec<u8>>();

            Ok(Response::new(full(reversed_body)))
        }

        _ => {
            let mut not_found = Response::new(empty());
            *not_found.status_mut() = StatusCode::NOT_FOUND;
            Ok(not_found)
        }
    }
}

fn empty() -> BoxBody<Bytes, hyper::Error> {
    Empty::<Bytes>::new()
        .map_err(|never| match never {})
        .boxed()
}
fn full<T: Into<Bytes>>(chunk: T) -> BoxBody<Bytes, hyper::Error> {
    Full::new(chunk.into())
        .map_err(|never| match never {})
        .boxed()
}

async fn parse_multipart(req: Request<hyper::body::Incoming>) {
    let data = req.into_body().collect().await.unwrap().to_bytes();

    //println!("{:?}", &data);

    let mut file = std::fs::File::create("dst/print_file.pdf").unwrap();
    file.write_all(&data).unwrap();
}