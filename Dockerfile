# Build Stage
FROM golang:1.25-alpine AS builder

WORKDIR /app

COPY go.mod ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o app

# Runtime stage
FROM alpine:latest

WORKDIR /app
COPY --from=builder /app/app .

EXPOSE 8080

CMD ["./app"]
