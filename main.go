package main

// Copyright 2016 Mathias Gumz. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// durl is a small CLI tool which generates data-uris from files. see
// https://tools.ietf.org/html/rfc2397 to read more about the data URL scheme

import (
	"bytes"
	"encoding/base64"
	"flag"
	"fmt"
	"io"
	"mime"
	"os"
	"path"
)

func main() {

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage of %s: %s file1 [file2] [file3]\n",
			os.Args[0], os.Args[0])
		flag.PrintDefaults()
	}

	flag.Parse()
	for _, name := range flag.Args() {
		mtype, err := detectMIME(name)
		if err != nil {
			fmt.Fprintf(os.Stderr, "%s: %q\n", name, err)
			continue
		}
		data, err := dataURI(name, mtype)
		if err == nil {
			fmt.Println(data)
		}
	}
}

func dataURI(name, mtype string) (string, error) {

	buf := bytes.NewBuffer(nil)
	buf.WriteString("data:")
	buf.WriteString(mtype)
	buf.WriteString(";base64,")

	r, err := os.Open(name)
	if err != nil {
		return "", err
	}
	defer r.Close()

	e := base64.NewEncoder(base64.StdEncoding, buf)

	io.Copy(e, r)
	e.Close()

	return buf.String(), nil
}

func detectMIME(name string) (string, error) {

	if ext := path.Ext(name); ext != "" {
		return mime.TypeByExtension(ext), nil
	}

	r, err := os.Open(name)
	if err != nil {
		return "", err
	}
	defer r.Close()

	s, err := r.Stat()
	if err != nil {
		return "", err
	}

	if s.IsDir() {
		return "", fmt.Errorf("%q is a directory. not supported", name)
	}

	lr := io.LimitReader(r, sniffLen)
	buf := bytes.NewBuffer(nil)

	_, err = io.Copy(buf, lr)
	if err != nil {
		return "", err
	}

	return DetectContentType(buf.Bytes()), nil
}
