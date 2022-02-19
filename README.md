# gorillamux-fargate-demo

This is a demo showing how to begin auditing HTTP requests using [auditrgorilla](https://github.com/auditr-io/auditr-agent-go/tree/main/wrappers/auditrgorilla) middleware

## Examples
Let's start with a basic server:
```
func main() {
	router := mux.NewRouter()
	router.HandleFunc("/health", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	router.HandleFunc("/hi/{name}", func(w http.ResponseWriter, r *http.Request) {
		vars := mux.Vars(r)

		w.Header().Add("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(fmt.Sprintf(`{
			"hi": "%s"
		}`, vars["name"])))
	})

	srv := &http.Server{
		Handler:      router,
		Addr:         ":8000",
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}
	log.Fatal(srv.ListenAndServe())
}
```

## Add the middleware
```

	a, err := auditrgorilla.NewAgent()
	if err != nil {
		log.Fatal(err)
	}

	router := mux.NewRouter()
	router.Use(a.Middleware)
    ...

```

## Running
We're going to host this on AWS ECS Fargate. The terraform configuration will create a new:
* ECS cluster
* Service
* Task definition
* VPC
* ALB
* ECR repository

### Build the docker image
You can either pass in the environment variables inline as you run the `make` commands:
```
    AUDITR_CONFIG_URL=https://config.auditr.io  AUDITR_API_KEY=prik_xxx \
        ACCOUNT={aws-account} REGION=us-west-2 PROFILE={aws-profile} make run
```

Or you can place your environment variables in a `.env` file:
```
ACCOUNT={aws-account}
REGION=us-west-2
PROFILE={aws-profile}
AUDITR_CONFIG_URL=https://config.auditr.io
AUDITR_API_KEY=prik_xxx
```
Then pass them into your `make` commands:
```
    env $(cat .env | xargs) make build
```

### Tag the image
```
    env $(cat .env | xargs) make tag
```

### Run the image to verify it's working
```
    env $(cat .env | xargs) make run
```
Try calling the `/health` endpoint to confirm the container's running:
```
	curl -I http://localhost:8000/health
	HTTP/1.1 200 OK
	Date: Sat, 19 Feb 2022 18:29:16 GMT
```

### Stop the image container
```
    env $(cat .env | xargs) make stop
```

### Initialize terraform
```
    env $(cat .env | xargs) make init
```

### Apply terraform plan
```
    env $(cat .env | xargs) make apply
```
After applying the plan, copy the ALB URL output. You're going to need it for testing.
```
alb_url = "http://gmuxdemo-dev-alb-462904767.us-west-2.elb.amazonaws.com"
```

### Push the docker image to the ECR repository
```
    env $(cat .env | xargs) make push
```

### Testing
Use the copied ALB URL output earlier to test:
```
    curl http://gmuxdemo-dev-alb-462904767.us-west-2.elb.amazonaws.com/hi/homer
```

### Cleanup
Don't forget to destory the AWS resources:
```
    env $(cat .env | xargs) make destroy
```
And remove the docker images:
```
    env $(cat .env | xargs) make clean
```
