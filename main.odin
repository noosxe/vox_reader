package vox_reader

import "core:fmt"
import "core:os"

FileHeader :: struct {
	signature: [4]byte,
	version:   u32,
}

ChunkHeader :: struct {
	id:           [4]byte,
	chunk_len:    u32,
	children_len: u32,
}

ModelSize :: struct {
	x: u32,
	y: u32,
	z: u32,
}

main :: proc() {
	if len(os.args) < 2 {
		fmt.println("please specify input file")
		os.exit(1)
	}

	filePath := os.args[1]
	fmt.printf("reading file: %s\n", filePath)

	file, err := os.open(filePath)
	if err != nil {
		fmt.eprintln(err)
		os.exit(1)
	}
	defer os.close(file)

	header := FileHeader{}
	_, err = os.read_ptr(file, rawptr(&header), size_of(FileHeader))
	if err != nil {
		fmt.eprintln(err)
		os.exit(1)
	}

	if header.signature != "VOX " {
		fmt.eprintln("invalid signature")
		os.exit(1)
	}

	fmt.printf("file version number: %d\n", header.version)
	chunk: string
	chunk, err = read_chunk_header(file)
	if err != nil {
		fmt.eprintln(err)
		os.exit(1)
	}
	if chunk != "MAIN" {
		fmt.eprintf("error: expected MAIN chunk but found: %s", chunk)
		os.exit(1)
	}

	chunk, err = read_chunk_header(file)
	if err != nil {
		fmt.eprintln(err)
		os.exit(1)
	}

	model_size: ModelSize
	if chunk == "SIZE" {
		model_size, err = read_model_size(file)
		if err != nil {
			fmt.eprintln(err)
			os.exit(1)
		}
	}

	chunk, err = read_chunk_header(file)
	if err != nil {
		fmt.eprintln(err)
		os.exit(1)
	}
}

read_chunk_header :: proc(file: os.Handle) -> (string, os.Error) {
	header := ChunkHeader{}
	_, err := os.read_ptr(file, rawptr(&header), size_of(ChunkHeader))
	if err != nil {
		return "", err
	}

	fmt.printf("chunk: %s\n", header.id)
	fmt.printf("len: %d\n", header.chunk_len)
	fmt.printf("children len: %d\n", header.children_len)

	return fmt.tprintf("%s", header.id), nil
}

read_model_size :: proc(file: os.Handle) -> (result: ModelSize, err: os.Error) {
	_, err = os.read_ptr(file, rawptr(&result), size_of(ModelSize))
	if err != nil {
		return
	}

	fmt.printf("model size: (%d, %d, %d)\n", result.x, result.y, result.z)

	return
}
