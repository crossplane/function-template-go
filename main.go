// Package main implements a Composition Function.
package main

import (
	"github.com/alecthomas/kong"

	"github.com/crossplane/function-sdk-go"
)

// CLI of this Function.
type CLI struct {
	function.CLI `kong:"embed"`
}

// Run this Function.
func (c *CLI) Run() error {
	log, err := c.Logger()
	if err != nil {
		return err
	}

	return function.Serve(&Function{log: log}, c.StandardOptions()...)
}

func main() {
	ctx := kong.Parse(&CLI{}, kong.Description("A Crossplane Composition Function."))
	ctx.FatalIfErrorf(ctx.Run())
}
