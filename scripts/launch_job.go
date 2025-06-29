package main

import (
	"context"
	"fmt"
	"os"

	batchv1 "k8s.io/api/batch/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

func main() {
	config, err := rest.InClusterConfig()
	if err != nil {
		panic(err.Error())
	}
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err.Error())
	}

	// TODO: Define your Job spec here (see k8s/*.yaml for reference)
	job := &batchv1.Job{
		// ... fill in Job spec ...
	}

	jobClient := clientset.BatchV1().Jobs("default")
	result, err := jobClient.Create(context.TODO(), job, metav1.CreateOptions{})
	if err != nil {
		panic(err)
	}
	fmt.Printf("Created job %q.\n", result.GetObjectMeta().GetName())

	// TODO: Add logic to pass secrets, monitor job, etc.
	os.Exit(0)
}
