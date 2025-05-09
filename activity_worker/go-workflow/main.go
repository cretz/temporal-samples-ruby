package main

import (
	"log"
	"time"

	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/temporal"
	"go.temporal.io/sdk/worker"
	"go.temporal.io/sdk/workflow"
)

// SayHelloWorkflow simply returns the result of the SayHelloActivity
func SayHelloWorkflow(ctx workflow.Context, name string) (string, error) {
	ctx = workflow.WithActivityOptions(ctx, workflow.ActivityOptions{
		// Give it only 5 seconds to schedule and run with no retries
		ScheduleToCloseTimeout: 5 * time.Second,
		RetryPolicy:            &temporal.RetryPolicy{MaximumAttempts: 1},
	})
	var response string
	err := workflow.ExecuteActivity(ctx, "SayHelloActivity", name).Get(ctx, &response)
	return response, err
}

func main() {
	// Create client to localhost on default namespace
	c, err := client.Dial(client.Options{})
	if err != nil {
		log.Fatalf("Failed creating client: %v", err)
	}
	defer c.Close()

	// Run workflow-only worker that does not handle activities
	w := worker.New(c, "activity-worker-sample", worker.Options{LocalActivityWorkerOnly: true})
	w.RegisterWorkflow(SayHelloWorkflow)
	log.Printf("Starting worker (ctrl+c to exit)")
	if err := w.Run(worker.InterruptCh()); err != nil {
		log.Fatalf("Worker failed to start: %v", err)
	}
}
