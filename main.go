package main

import (
	"bytes"
	"log"
	"net/http"
	"os"
	"os/exec"
)

func bench(rw http.ResponseWriter, r *http.Request) {
	var args []string
	for key, values := range r.URL.Query() {
		for _, value := range values {
			arg := key
			if value != "" {
				arg = arg + "=" + value
			}
			args = append(args, arg)
		}
	}

	stderr := &bytes.Buffer{}
	run := exec.Command("vegeta", args...)
	log.Println("run:", run.Path, " ", run.Args)
	run.Stdin = r.Body
	run.Stdout = rw
	run.Stderr = stderr

	if err := run.Run(); err != nil {
		http.Error(rw, stderr.String(), http.StatusBadRequest)
		return
	}
}

func main() {
	http.HandleFunc("/vegeta", bench)
	log.Fatal(http.ListenAndServe(os.Getenv("ADDR")+":"+os.Getenv("PORT"), nil))
}
