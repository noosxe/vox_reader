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

XYZI :: struct {
    x: u8,
    y: u8,
    z: u8,
    i: u8,
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

    if chunk == "XYZI" {
        voxels, err := read_xyzi(file, context.temp_allocator)
        if err != nil {
            fmt.eprintln(err)
            os.exit(1)
        }
    }

    chunk, err = read_chunk_header(file)

    if chunk == "RGBA" {
        palette, err := read_palette(file)
        if err != nil {
            fmt.eprintln(err)
            os.exit(1)
        }

        for color in palette {
            fmt.printf("%x\n", color)
        }
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

read_xyzi :: proc(file: os.Handle, allocator := context.allocator) -> ([]XYZI, os.Error) {
    num_voxels: u32
    _, err := os.read_ptr(file, rawptr(&num_voxels), size_of(u32))
    if err != nil {
        return nil, err
    }

    voxels := make([]XYZI, num_voxels, allocator)
    _, err = os.read_ptr(file, raw_data(voxels), size_of(u32) * int(num_voxels))
    if err != nil {
        return nil, err
    }

    fmt.printf("num voxels: %d\n", num_voxels)

    return voxels, nil
}

read_palette :: proc(file: os.Handle) -> (palette: [256]u32, err: os.Error) {
    _, err = os.read_ptr(file, raw_data(&palette), 256 * size_of(u32))
    if err != nil {
        return
    }

    return
}
