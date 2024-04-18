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

use printers;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    //let addr = SocketAddr::from(([127, 0, 0, 1], 3000));
    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));

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

        (&Method::GET, "/printers") => {
            //let mut vec = Vec::new();
            let mut printer_string: String = "{\"printers\":[".to_string();
            let printer_list = printers::get_printers();

            for printer in printer_list.clone() {
                // vec.push(printer.system_name);
                // printer_string += &(printer.system_name + ",").to_string();
                printer_string += &format!("\"{}\",", printer.system_name).as_str();
            }
            printer_string.remove(printer_string.len() - 1);
            printer_string += "]}";

            println!("{}", &printer_string);
            
            Ok(Response::new(full(printer_string)))
        },

        //(&Method::POST, "/printers") => {
        //    let data = req.into_body().collect().await.unwrap().to_bytes();
        //    selected_printer = std::str::from_utf8(&data).unwrap();
        //    println!("Printer {} selected", selected_printer);
        //    Ok(Response::new(full("Printer selected")))
        //},

        (&Method::POST, "/echo") => Ok(Response::new(req.into_body().boxed())),

        (&Method::POST, "/print") => {
            let selected_printer = req.headers().get("printer").unwrap().to_str().unwrap().to_string();
            _ = parse_multipart(req).await;
            
            println!("Currently selected printer: {}", selected_printer);
            //if selected_printer != "" {
            //    println!("Printing from: {}", &selected_printer);
            //    let status1 = printers::print_file(&selected_printer, "dst/print_file.pdf", None);
            //    
            //    match status1 {
            //        Ok(_) => {
            //            return Ok(Response::new(full("Printed...")));
            //        },
            //        Err(value) => {
            //            return Ok(Response::new(full(value)));
            //        }
            //    }
            //}

            //Ok(Response::new(full("Print failed...!")))
            let printers_list = printers::get_printers();

            println!("{:?}", printers_list);

            if printers_list.len() > 0 {
                let printer: printers::printer::Printer ;
                match selected_printer.parse::<usize>() {
                    Ok(n) => {
                        printer = printers_list[n].clone();
                        let _status1 = printer.print_file("dst/print_file.pdf", None);

                        match _status1 {
                            Ok(_) => {
                                return Ok(Response::new(full("Printed...")));
                            },
                            Err(u) => {
                                return Ok(Response::new(full(u)));
                            }
                        }
                    },
                    Err(_) => {
                        return Ok(Response::new(full("Parsing failed!")));
                    }
                }
            }
                Ok(Response::new(full("Print failed...!")))

                // let _status1 = printer.print_file("dst/print_file.pdf", None);
                // Ok(Response::new(full("Printed...")))
            // } else {
                // Ok(Response::new(full("Print failed!")))
            // }
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
