PKG=github.com/gengo/grpc-gateway
GO_PLUGIN=bin/protoc-gen-go
GO_PLUGIN_PKG=github.com/golang/protobuf/protoc-gen-go
GATEWAY_PLUGIN=bin/protoc-gen-grpc-gateway
GATEWAY_PLUGIN_PKG=$(PKG)/protoc-gen-grpc-gateway
GATEWAY_PLUGIN_SRC=protoc-gen-grpc-gateway/main.go \
		   protoc-gen-grpc-gateway/generator.go
OPTIONS_GO=options/options.pb.go
OPTIONS_PROTO=options/options.proto
PKGMAP=Mgoogle/protobuf/descriptor.proto=$(GO_PLUGIN_PKG)/descriptor,Mexamples/sub/message.proto=$(PKG)/examples/sub
EXAMPLES=examples/echo_service.proto \
	 examples/a_bit_of_everything.proto
EXAMPLE_SVCSRCS=$(EXAMPLES:.proto=.pb.go)
EXAMPLE_GWSRCS=$(EXAMPLES:.proto=.pb.gw.go)
EXAMPLE_DEPS=examples/sub/message.proto
EXAMPLE_DEPSRCS=$(EXAMPLE_DEPS:.proto=.pb.go)
PROTOC_INC_PATH=$(dir $(shell which protoc))/../include

generate: $(OPTIONS_GO)

.SUFFIXES: .go .proto

$(GO_PLUGIN): 
	go get $(GO_PLUGIN_PKG)
	go build -o $@ $(GO_PLUGIN_PKG)

$(OPTIONS_GO): $(OPTIONS_PROTO) $(GO_PLUGIN)
	protoc -I $(PROTOC_INC_PATH)  -I. --plugin=$(GO_PLUGIN) --go_out=$(PKGMAP):. $(OPTIONS_PROTO)

$(GATEWAY_PLUGIN): $(OPTIONS_GO) $(GATEWAY_PLUGIN_SRC)
	go build -o $@ $(GATEWAY_PLUGIN_PKG)

$(EXAMPLE_SVCSRCS): $(GO_PLUGIN) $(EXAMPLES)
	protoc -I $(PROTOC_INC_PATH) -I. --plugin=$(GO_PLUGIN) --go_out=$(PKGMAP),plugins=grpc:. $(EXAMPLES)
$(EXAMPLE_DEPSRCS): $(GO_PLUGIN) $(EXAMPLE_DEPS)
	protoc -I $(PROTOC_INC_PATH) -I. --plugin=$(GO_PLUGIN) --go_out=$(PKGMAP),plugins=grpc:. $(EXAMPLE_DEPS)
$(EXAMPLE_GWSRCS): $(GATEWAY_PLUGIN) $(EXAMPLES)
	protoc -I $(PROTOC_INC_PATH) -I. --plugin=$(GATEWAY_PLUGIN) --grpc-gateway_out=logtostderr=true,import_prefix=$(PKG):. $(EXAMPLES)

test: $(EXAMPLE_SVCSRCS) $(EXAMPLE_GWSRCS) $(EXAMPLE_DEPSRCS)
	go test $(PKG)/...

realclean:
	rm -f $(OPTIONS_GO)
	rm -f $(EXAMPLE_SVCSRCS) $(EXAMPLE_DEPSRCS)
	rm -f $(EXAMPLE_GWSRCS)
