#python3 live_fpga_square.py --pico /dev/tty.usbmodem1101
#python3 live_fpga_square.py --pico /dev/tty.usbmodem1101 --seconds 10


import argparse
import os
import time
import wave
import serial
import sounddevice as sd


OUTPUTDIR = "output"
SAMPLERATE = 8000
MAGIC = b"SQW1\n" #pico sends this at stream start
STARTCOMMAND = b"C" 
READCHUNK = 512


def waitForPico(ser: serial.Serial, timeoutS: float = 5.0) -> None:
    deadline = time.time() + timeoutS
    window = bytearray()

    while time.time() < deadline:
        byte = ser.read(1)
        if not byte:
            continue

        window += byte
        if len(window) > len(MAGIC):
            del window[0 : len(window) - len(MAGIC)]

        if bytes(window) == MAGIC:
            return

    raise TimeoutError("Timed out waiting for Pico stream marker SQW1")


def openWav(path: str) -> wave.Wave_write:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    wav = wave.open(path, "wb")
    wav.setnchannels(1)
    wav.setsampwidth(1)
    wav.setframerate(SAMPLERATE)
    return wav


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Live play the FPGA synth from the Pico"
    )
    parser.add_argument("--pico", default="/dev/ttyACM0", help="Pico USB serial port")
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--seconds", type=float, default=0.0, help="0 means run forever")
    parser.add_argument("--no-play", action="store_true", help="receive stream without audio playback")
    parser.add_argument("--save", default="", help="also save the stream as a WAV in output/")
    args = parser.parse_args()

    audioStream = None
    wav = None
    sampleLimit = int(args.seconds * SAMPLERATE) if args.seconds > 0 else 0
    received = 0
    nextStatusAt = time.time() + 1.0
    statusSamples = 0
    statusMin = 255
    statusMax = 0

#if the no_play flag we wont stream
#debugging
    if not args.no_play:
        audioStream = sd.RawOutputStream(
            samplerate=SAMPLERATE,
            channels=1,
            dtype="uint8",
            blocksize=READCHUNK,
        )
        audioStream.start()
#save wav file to output dir
    if args.save:
        output_path = args.save
        if not os.path.isabs(output_path):
            output_path = os.path.join(OUTPUTDIR, output_path)
        wav = openWav(output_path)
        print(f"Saving .wav to {output_path}")

    print(f"Opening Pico port {args.pico}")

#multiple flags for debugging
#tests pico connection, output baud, with a longer timeout
    try:
        with serial.Serial(args.pico, args.baud, timeout=2) as ser:
            time.sleep(2)
            ser.reset_input_buffer()
            ser.write(STARTCOMMAND)
            ser.flush()

            print("Waiting for Pico stream marker")
            waitForPico(ser)
            print("Streaming has started!")

#we read the chunks from the 8 bit samples
#if our sample limit is 0 we run forever,
            while sampleLimit == 0 or received < sampleLimit:
                count = READCHUNK
                if sampleLimit:
                    count = min(count, sampleLimit - received) 

                chunk = ser.read(count)
                if not chunk:
                    continue

                received += len(chunk) #how many samples we have received
                statusSamples += len(chunk)
                statusMin = min(statusMin, min(chunk))
                statusMax = max(statusMax, max(chunk))

                if audioStream is not None:
                    audioStream.write(bytes(chunk)) #write to speakers

                if wav is not None:
                    wav.writeframes(chunk) #write to wav file

                now = time.time()
                if now >= nextStatusAt:
                    print(
                        f"received = {received} "
                        f"rate~{statusSamples}/s "
                        f"byte_min = {statusMin} "
                        f"byte_max = {statusMax}"
                    )
                    nextStatusAt = now + 1.0
                    statusSamples = 0
                    statusMin = 255
                    statusMax = 0
    except KeyboardInterrupt:
        print("\nStopped.")
    finally:
        if wav is not None:
            wav.close()
        if audioStream is not None:
            audioStream.stop()
            audioStream.close()

    print(f"Received {received} samples ({received / SAMPLERATE:.2f} seconds).")


if __name__ == "__main__":
    main()
