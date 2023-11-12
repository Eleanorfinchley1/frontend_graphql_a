FROM golang:1.16

WORKDIR /go/src/agora_token_generator
COPY . .

RUN go build -o agora_token_generator main.go
RUN go install -v ./...

ENTRYPOINT ["./agora_token_generator"]
