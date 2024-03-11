use std::{
    fs,
    io,
    io::{prelude::*, BufReader},
    net::{TcpListener, TcpStream},
    thread,
    time::Duration,
};
use threadpool::ThreadPool;

fn main() {
    let listener = TcpListener::bind("127.0.0.1:7878").unwrap();
    let pool = ThreadPool::new(4);

    for stream in listener.incoming() {
        let stream = stream.unwrap();

        pool.execute(|| {
            let _ = handle_connection(stream);
        });
    }
}

fn handle_connection(mut stream: TcpStream) -> io::Result<()>{
    let mut buf_reader = BufReader::with_capacity(10*1024*1024, &mut stream);
    let mut data: Vec<String> = Vec::new();
    //let mut request_line = String::new();
    //let buf_reader = BufReader::new(&mut stream);

    //let mut i = 0;
    let mut message = String::new();

    loop {
        message.clear();
        if buf_reader.read_line(&mut message).expect("Cannot read new line") == 0 {
            break;
        } else {
            data.push(String::from(message.trim()));
            println!("{}", message.trim());
            if message.starts_with("Cookie") {
                break;
            }
        }
    }

    let request_line = &data[0];

    //for line in buf_reader.lines() {
    //    if i == 0 { 
    //        request_line = line?;
    //        println!("{}", &request_line);
    //    } else {
    //        println!("{}", line?); 
    //    }
    //    i += 1;

    //    if i == 50 {
    //        break;
    //    }
    //}

    //let request_line = &buf_reader.lines().next().unwrap().unwrap();
    //println!("{request_line}"); // => POST /fileupload HTTP/1.1

    let (status_line, filename) = match &request_line[..] {
        "GET / HTTP/1.1" => ("HTTP/1.1 200 OK", "hello.html"),
        "GET /sleep HTTP/1.1" => {
            thread::sleep(Duration::from_secs(5));
            ("HTTP/1.1 200 OK", "hello.html")
        }
        "GET /upload HTTP/1.1" => ("HTTP/1.1 200 OK", "upload.html"),
        "POST /fileupload HTTP/1.1" => ("HTTP/1.1 200 OK", "hello.html"),
        _ => ("HTTP/1.1 404 NOT FOUND", "404.html")
    };

    let contents = fs::read_to_string(filename).unwrap();
    let length = contents.len();

    let response =
        format!("{status_line}\r\nContent-Length: {length}\r\n\r\n{contents}");

    stream.write_all(response.as_bytes()).unwrap();
    
    Ok(())
}
