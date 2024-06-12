### PoC

Here's what I want to do:

- Create a c++ application (here, open the calculator)
- Output shellcode with donut from `opencalc.exe`
- Output the bytes of this shellcode
- Decompile putty, put the shellcode inside
- Execute the shellcode, then move on to running putty.

Double-click on putty to open both the calculator and putty.

### Quick explanation:

From what I understand donut, generates a shellcode of the given PE. But also a loader that will be used to inject the shellcode into the program.

You end up with 25 kB of bytes used for this, and it takes a long time to analyze it properly.

The loader “creates” the original program (bytes for bytes) in the putty thread.

The shellcode has almost no bytes in common with the PE (`opencalc.exe`).
However, once the loader has loaded the shellcode into the program, the bytes are similar to the original decompiled PE (`opencalc.exe`).

A shellcode includes the program's execution bytes. These bytes have absolutely nothing to do with the original program bytes, they are build bytes for the shellcode.

A loader is around the shellcode to load it into putty (without this there is no entry point).


Every compiled program has a code return for execution. this return will kill the thread.

Our program (`opencalc.exe`) has a `return 5520`.

The loader around the shellcode also has a return (it can also be blocked with an option).


The challenge is to load the shellcode (with or without return) into putty. Continue executing the shellcode until the end, or in a new thread that won't kill itself, if you like.
Finally, once this is done, we'll jump to the first instrctions of putty to continue executing putty.



### Problems encountered :

- It's almost impossible (or at least I haven't found it) to read the entire loader and find the exact location of the shellcode (it's not the same bytes as opencalc.exe) where the kill process instrcutions are located.

- I tried to modify the `return 5520` of my program by decompiling it, because it's necessarily the first return that arrives.
    - If I can jump to the first putty instruction instead of doing the `5520 return`, I've got it.
The problem is that the loader loads the shellcode into an area of memory that can't be written to, so you can't jump from here.


- I modified `return 5520` by decompiling `opencalc.exe`, replaced the return bytes by just null bytes, then patched the .exe.
    - I take out the shellcode, paste and patch putty. And it does have a null bytes exception. But there are still some in the thread that can't be written. So it's impossible to change


- Based on the above principle, I thought I'd jump to the offset of the first putty instruction, but directly by decompiling `opencalc.exe` instead of the null bytes. This time the problem is that `opencalc.exe` doesn't have the putty reference, so I'm going to jump blindly into an offset that's generated randomly with each new execution.


### Go

Here is the calculator code, I intentionally put a return with the number 5520 to easily find it in the hex.

Build in 32bits with Visual Studio.

```
#include <cstdlib>
#include <iostream>

int main() {
    system("calc");
    return 5520;
}

```
![opencalc.exe](./img/opencalc.gif).

Next, we generate the shellcode.

- Specify:
    - `-a 1` x86 application
    - `-z 2` aPlib Compression
    - `-x 3` Block in the thread
    - `-f 1` Binary Format

![opencalc.exe](./img/shellcode.png).


From there, we will extract the shellcode bytes with HxD. CTRL + A


![opencalc.exe](./img/hxd.png).


We will decompile the modified Putty with the code cave (here it will already be) which is .codeex.
And copy the shellcode into the correct memory zone.

I add `pushad` and `pushfd` at the beginning of the shellcode.

![opencalc.exe](./img/puttyshell.gif).

Next, I will modify certain instructions next to Putty's entry point.
It is necessary to save the instructions to restore them at the end of the shellcode.

We will jump directly into the shellcode.

![opencalc.exe](./img/puttyshelljmp.gif).

Finally, at the end of the shellcode, we will restore the lines changed during the jump into the shellcode. Thus, we jump again to push 0x1 to return to the point where we jumped to the shellcode.

![opencalc.exe](./img/shelljmp.png).


From here, I am stuck; we need to remove the `return 5520` from `opencalc.exe`. And that from the loader, but if I can find the shellcode location that builds the `return 5520`, I would just need to jump at the end of the shellcode to this location.


## Troubleshooting
### If I run Putty with what I did above:

![opencalc.exe](./img/puttyplusshell.gif).

- The return code is 5520, we are surely at the return of the program.

It’s too difficult to reach the end of the program because there are too many instructions, but don’t panic, look at the second one to understand that even if I find the return in the thread, I won’t be able to write.

### If I directly break the return 5520 in the program

We decompile opencalc.exe.
We will replace the Exit with null bytes to provoke an exception.

![opencalc.exe](./img/shellexit.png).

I extract the shellcode and put it in Putty similar to the tutorial above.

Then we will decompile the Putty with the shellcode with the null bytes exception.

![opencalc.exe](./img/shellcodenullbytes.gif).

We find our null bytes; from there, it would be a win if I could jump to the end of the shellcode (where the Putty instructions are) instead of these null bytes.

But the memory zone being the main thread, is not writable.

![opencalc.exe](./img/errorecritable.gif).

![opencalc.exe](./img/error1.png).
![opencalc.exe](./img/error2.png).
