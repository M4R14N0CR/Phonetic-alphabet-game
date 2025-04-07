<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
</head>
<body>
  <h1>Phonet alphabet game</h1>

  <h2>Overview</h2>
  <p>
    THis homework was about a bootable game implemented in x86 assembly that tests your knowledge of the phonetic alphabet.
    During the boot process, the game is loaded via a custom bootloader from a USB drive, and it challenges you by generating four random sequences.
    Each sequence requires you to type the corresponding phonetic word (using the radio telephone alphabet).
    Every correct response adds a point, and your score accumulates over rounds.
  </p>

  <h2>Installation and Execution</h2>
  <p>Follow these steps to compile and run the game:</p>
  <ol>
    <li>
      <p><strong>Compile the Assembly Files</strong></p>
      <p>Use NASM to compile the bootloader and game source code:</p>
      <pre><code>nasm -f bin boot.asm -o boot.bin
nasm -f bin MRPV.asm -o MRPV.bin</code></pre>
    </li>
    <li>
      <p><strong>Create a Disk Image</strong></p>
      <p>Generate a blank disk image (using 2048 sectors of 512 bytes):</p>
      <pre><code>dd if=/dev/zero of=disk.img bs=512 count=2048</code></pre>
    </li>
    <li>
      <p><strong>Write the Bootloader</strong></p>
      <p>Write the bootloader binary to the first 512 bytes of the disk image:</p>
      <pre><code>dd if=boot.bin of=disk.img bs=512 count=1 conv=notrunc</code></pre>
    </li>
    <li>
      <p><strong>Write the Game Binary</strong></p>
      <p>Write the game binary to the image starting from the second block:</p>
      <pre><code>dd if=MRPV.bin of=disk.img bs=512 seek=1 conv=notrunc</code></pre>
    </li>
    <li>
      <p><strong>Deploy the Image to USB</strong></p>
      <p>Replace <code>/dev/sdX</code> with your USB device identifier:</p>
      <pre><code>sudo dd if=disk.img of=/dev/sdX bs=512 status=progress</code></pre>
    </li>
  </ol>

  <h2>How It Works</h2>
  <ul>
    <li>
      <p><strong>Bootloader Phase:</strong></p>
      <ul>
        <li>The bootloader disables interrupts and sets up data, extra, and stack segments.</li>
        <li>It reads 4 sectors (starting from sector 2) from the disk into memory.</li>
        <li>After loading, it jumps to a new memory location (0x8000) where the game code resides.</li>
      </ul>
    </li>
    <li>
      <p><strong>Game Phase:</strong></p>
      <ul>
        <li><strong>Input Handling:</strong> Clears the input buffer, reads user keystrokes, and displays input.</li>
        <li><strong>String Comparison:</strong> Compares the user input with the pre-stored correct phonetic word.</li>
        <li><strong>Random Generation:</strong> Uses a linear congruential generator to select a random letter from the alphabet.</li>
        <li><strong>Phonetic Conversion:</strong> Maps the random letter to its corresponding phonetic word.</li>
        <li><strong>Scoring:</strong> Increments the player's score for correct responses and provides immediate feedback.</li>
      </ul>
    </li>
  </ul>


</body>
</html>
