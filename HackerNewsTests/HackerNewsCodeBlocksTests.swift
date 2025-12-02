import Foundation
import Testing
@testable import HackerNews

struct HackerNewsCodeBlocksTests {
    private let markdown = MarkdownService()

    @Test func comment45679839() async throws {
        let html = #"""
<p>I have a bunch, but one that I rarely see mentioned but use all the time is memo(1) (<a href="https:&#x2F;&#x2F;github.com&#x2F;aktau&#x2F;dotfiles&#x2F;blob&#x2F;master&#x2F;bin&#x2F;memo" rel="nofollow">https:&#x2F;&#x2F;github.com&#x2F;aktau&#x2F;dotfiles&#x2F;blob&#x2F;master&#x2F;bin&#x2F;memo</a>).<p>It memoizes the command passed to it.<p><pre><code>  $ memo curl https:&#x2F;&#x2F;some-expensive.com&#x2F;api&#x2F;call | jq . | awk &#x27;...&#x27;
</code></pre>
Manually clearing it (for example if I know the underlying data has changed:<p><pre><code>  $ memo -c curl https:&#x2F;&#x2F;some-expensive.com&#x2F;api&#x2F;call
</code></pre>
In-pipeline memoization (includes the input in the hash of the lookup):<p><pre><code>  $ cat input.txt | memo -s expensive-processor | awk &#x27;...&#x27;
</code></pre>
This allows me to rapidly iterate on shell pipelines. The main goal is to minimize my development latency, but it also has positive effects on dependencies (avoiding redundant RPC calls). The classic way of doing this is storing something in temporary files:<p><pre><code>  $ curl https:&#x2F;&#x2F;some-expensive.com&#x2F;api&#x2F;call &gt; tmpfile
  $ cat tmpfile | jq . | awk &#x27;...&#x27;
</code></pre>
But I find this awkward, and makes it harder than necessary to experiment with the expensive command itself.<p><pre><code>  $ memo curl https:&#x2F;&#x2F;some-expensive.com&#x2F;api&#x2F;call | jq . | awk &#x27;...&#x27;
  $ memo curl --data &quot;param1=value1&quot; https:&#x2F;&#x2F;some-expennsive.com&#x2F;api&#x2F;call | jq . | awk &#x27;...&#x27;
</code></pre>
Both of those will run curl once.<p>NOTE: Currently environment variables are not taken into account when hashing.
"""#
        let expected = #"""
I have a bunch, but one that I rarely see mentioned but use all the time is memo(1) ([https://github.com/aktau/dotfiles/blob/master/bin/memo](https://github.com/aktau/dotfiles/blob/master/bin/memo)).

It memoizes the command passed to it.

```
$ memo curl https://some-expensive.com/api/call | jq . | awk '...'
```
Manually clearing it (for example if I know the underlying data has changed:

```
$ memo -c curl https://some-expensive.com/api/call
```
In-pipeline memoization (includes the input in the hash of the lookup):

```
$ cat input.txt | memo -s expensive-processor | awk '...'
```
This allows me to rapidly iterate on shell pipelines. The main goal is to minimize my development latency, but it also has positive effects on dependencies (avoiding redundant RPC calls). The classic way of doing this is storing something in temporary files:

```
$ curl https://some-expensive.com/api/call > tmpfile
$ cat tmpfile | jq . | awk '...'
```
But I find this awkward, and makes it harder than necessary to experiment with the expensive command itself.

```
$ memo curl https://some-expensive.com/api/call | jq . | awk '...'
$ memo curl --data "param1=value1" https://some-expennsive.com/api/call | jq . | awk '...'
```
Both of those will run curl once.

NOTE: Currently environment variables are not taken into account when hashing.
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45682219() async throws {
        let html = #"""
<p>You&#x27;re gonna absolutely love up (<a href="https:&#x2F;&#x2F;github.com&#x2F;akavel&#x2F;up" rel="nofollow">https:&#x2F;&#x2F;github.com&#x2F;akavel&#x2F;up</a>).<p>If you pipe curl&#x27;s output to it, you&#x27;ll get a live playground where you can finesse the rest of your pipeline.<p><pre><code>  $ curl https:&#x2F;&#x2F;some-expensive.com&#x2F;api&#x2F;call | up</code></pre>
"""#
        let expected = #"""
You're gonna absolutely love up ([https://github.com/akavel/up](https://github.com/akavel/up)).

If you pipe curl's output to it, you'll get a live playground where you can finesse the rest of your pipeline.

```
$ curl https://some-expensive.com/api/call | up
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45682426() async throws {
        let html = #"""
<p>up(1) looks really cool, I think I&#x27;ll add it to my toolbox.<p>It looks like up(1) and memo(1) have similar use cases (or goals). I&#x27;ll give it a try to see if I can appreciate its ergonomics. I suspect memo(1) will remain my mainstay:<p><pre><code>  1. After executing a pipeline, I like to press the up arrow (heh) and edit. Surprisingly often I need to edit something that&#x27;s *not* the last part, but somewhere in the middle. I find this cumbersome in default line editing mode, so I will often drop into my editor (^X^E) to edit the command.
  2. Up seems to create a shell command after completion. Avoiding the creation of extra files was one of my goals for memo(1). I&#x27;m sure some smart zsh&#x2F;bash integration could be made that just returns the completed command after completing.</code></pre>
"""#
        let expected = #"""
up(1) looks really cool, I think I'll add it to my toolbox.

It looks like up(1) and memo(1) have similar use cases (or goals). I'll give it a try to see if I can appreciate its ergonomics. I suspect memo(1) will remain my mainstay:

```
1. After executing a pipeline, I like to press the up arrow (heh) and edit. Surprisingly often I need to edit something that's *not* the last part, but somewhere in the middle. I find this cumbersome in default line editing mode, so I will often drop into my editor (^X^E) to edit the command.
2. Up seems to create a shell command after completion. Avoiding the creation of extra files was one of my goals for memo(1). I'm sure some smart zsh/bash integration could be made that just returns the completed command after completing.
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45681027() async throws {
        let html = #"""
<p>Another thing I built into memo(1) which I forgot to mention: automatic compression. memo(1) will use available (de)compressors (in order of preference: zstd, lz4, xz, gzip) to (de)compress stored contents. It&#x27;s surprising how much disk space and IOPS can be saved this way due to redundancy.<p>I currently only have two memoized commands:<p><pre><code>  $ for f in &#x2F;tmp&#x2F;memo&#x2F;aktau&#x2F;* ; do 
      ls -lh &quot;$f&quot; =(zstd -d &lt; $f) 
    done
  -rw-r----- 1 aktau aktau  33K &#x2F;tmp&#x2F;memo&#x2F;aktau&#x2F;0742a9d8a34c37c0b5659f7a876833b6dad9ec689f8f5c6065d05f8a27d993c7bbcbfdc3a7337c3dba17886d6f6002e95a434e4629.zst
  -rw------- 1 aktau aktau 335K &#x2F;tmp&#x2F;zshSQRwR9

  -rw-r----- 1 aktau aktau  827 &#x2F;tmp&#x2F;memo&#x2F;aktau&#x2F;8373b3af893222f928447acd410779182882087c6f4e7a19605f5308174f523f8b3feecbc14e1295447f45b49d3f06da5da7e8d7a6.zst
  -rw------- 1 aktau aktau 7.4K &#x2F;tmp&#x2F;zshlpMMdo
</code></pre>
That&#x27;s roughly 10x compression ratio.
"""#
        let expected = #"""
Another thing I built into memo(1) which I forgot to mention: automatic compression. memo(1) will use available (de)compressors (in order of preference: zstd, lz4, xz, gzip) to (de)compress stored contents. It's surprising how much disk space and IOPS can be saved this way due to redundancy.

I currently only have two memoized commands:

```
$ for f in /tmp/memo/aktau/* ; do 
    ls -lh "$f" =(zstd -d < $f) 
  done
-rw-r----- 1 aktau aktau  33K /tmp/memo/aktau/0742a9d8a34c37c0b5659f7a876833b6dad9ec689f8f5c6065d05f8a27d993c7bbcbfdc3a7337c3dba17886d6f6002e95a434e4629.zst
-rw------- 1 aktau aktau 335K /tmp/zshSQRwR9
-rw-r----- 1 aktau aktau  827 /tmp/memo/aktau/8373b3af893222f928447acd410779182882087c6f4e7a19605f5308174f523f8b3feecbc14e1295447f45b49d3f06da5da7e8d7a6.zst
-rw------- 1 aktau aktau 7.4K /tmp/zshlpMMdo
```
That's roughly 10x compression ratio.
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45688805() async throws {
        let html = #"""
<p>.<p><pre><code>   #!&#x2F;usr&#x2F;bin&#x2F;env bash
   #
   # memo(1), memoizes the output of your command-line, so you can do:
   #
   #  $ memo &lt;some long running command&gt; | ...
   #
   # Instead of
   #
   #  $ &lt;some long running command&gt; &gt; tmpfile
   #  $ cat tmpfile | ...
   #  $ rm tmpfile
   
   to save output, sed can be used in the pipeline instead of tee
   for example,
   
   x=$(mktemp -u);
   test -p $x||mkfifo $x;
   zstd -19 &lt; $x &gt; tmpfile.zst &amp;
   &lt;long running command&gt;|sed w$x|&lt;rest of pipeline&gt;;
   
   # You can even use it in the middle of a pipe if you know that the input is not
   # extremely long. Just supply the -s switch:
   #
   #  $ cat sitelist | memo -s parallel curl | grep &quot;server:&quot;
   
   grep can be replaced with sed and search results sent to stderr
   
   &lt; sitelist curl ...|sed &#x27;&#x2F;server:&#x2F;w&#x2F;dev&#x2F;stderr&#x27;|zstd -19 &gt;tmpfile.zst;
   
   or send search results to stderr and to some other file
   sed can save output to multiple files at a time
   
   &lt; sitelist curl ...|sed -e &#x27;&#x2F;server:&#x2F;w&#x2F;dev&#x2F;stderr&#x27; -e &quot;&#x2F;server:&#x2F;wresults.txt&quot;|zstd -19 &gt;tmpfile.zst;</code></pre>
"""#
        let expected = #"""
.

```
#!/usr/bin/env bash
#
# memo(1), memoizes the output of your command-line, so you can do:
#
#  $ memo <some long running command> | ...
#
# Instead of
#
#  $ <some long running command> > tmpfile
#  $ cat tmpfile | ...
#  $ rm tmpfile
to save output, sed can be used in the pipeline instead of tee
for example,
x=$(mktemp -u);
test -p $x||mkfifo $x;
zstd -19 < $x > tmpfile.zst &
<long running command>|sed w$x|<rest of pipeline>;
# You can even use it in the middle of a pipe if you know that the input is not
# extremely long. Just supply the -s switch:
#
#  $ cat sitelist | memo -s parallel curl | grep "server:"
grep can be replaced with sed and search results sent to stderr
< sitelist curl ...|sed '/server:/w/dev/stderr'|zstd -19 >tmpfile.zst;
or send search results to stderr and to some other file
sed can save output to multiple files at a time
< sitelist curl ...|sed -e '/server:/w/dev/stderr' -e "/server:/wresults.txt"|zstd -19 >tmpfile.zst;
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45694247() async throws {
        let html = #"""
<p>I was not aware of bkt. Thanks for the link. It seems very similar to memo, and has more features:<p><pre><code>  - Explicit TTL
  - Ability to include working directory et al. as context for the cache key.
</code></pre>
There do appear to be downsides (from my PoV) as well:<p><pre><code>  - It&#x27;s a rust program, so it needs to be compiled (memo is a bash&#x2F;zsh script and runs as-is).
  - There&#x27;s no mention of transparent compression, either in the README or through simple source code search. I did find https:&#x2F;&#x2F;github.com&#x2F;dimo414&#x2F;bkt&#x2F;issues&#x2F;62 which mentions swappable backends. The fact that it uses some type of database instead of just the filesystem is not a positive for me, I prefer the state to be easy to introspect with common tools. I will often memo commands that output gigabytes of data, which is usually highly compressible. Transparent compression fixes that up. One could argue this could be avoided with a filesystem-level feature, like ZFS transparent compression. But I don&#x27;t know how to detect that in a cross-FS fashion.
</code></pre>
I opened <a href="https:&#x2F;&#x2F;github.com&#x2F;dimo414&#x2F;bkt&#x2F;discussions&#x2F;63" rel="nofollow">https:&#x2F;&#x2F;github.com&#x2F;dimo414&#x2F;bkt&#x2F;discussions&#x2F;63</a> so the author of bkt can perhaps also participate.
"""#
        let expected = #"""
I was not aware of bkt. Thanks for the link. It seems very similar to memo, and has more features:

```
- Explicit TTL
- Ability to include working directory et al. as context for the cache key.
```
There do appear to be downsides (from my PoV) as well:

```
- It's a rust program, so it needs to be compiled (memo is a bash/zsh script and runs as-is).
- There's no mention of transparent compression, either in the README or through simple source code search. I did find https://github.com/dimo414/bkt/issues/62 which mentions swappable backends. The fact that it uses some type of database instead of just the filesystem is not a positive for me, I prefer the state to be easy to introspect with common tools. I will often memo commands that output gigabytes of data, which is usually highly compressible. Transparent compression fixes that up. One could argue this could be avoided with a filesystem-level feature, like ZFS transparent compression. But I don't know how to detect that in a cross-FS fashion.
```
I opened [https://github.com/dimo414/bkt/discussions/63](https://github.com/dimo414/bkt/discussions/63) so the author of bkt can perhaps also participate.
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45682053() async throws {
        let html = #"""
<p>The default storage location for memo(1) output is &#x2F;tmp&#x2F;memo&#x2F;${USER}. Most distributions either have some automatic periodic cleanup, and&#x2F;or wipe it on restart.<p>Separately from that:<p><pre><code>  - The invocation contains *memo* right in there, so you (the user) knows that it might memoize.
  - One uses memo(1) for commands that are generally slow. Rerunning your command that has a slow part and having it return in a millisecond while you weren&#x27;t expecting it should make the spider-sense tingle.
</code></pre>
In practice, this has never been a problem for me, and I&#x27;ve used this hacked together command for years.
"""#
        let expected = #"""
The default storage location for memo(1) output is /tmp/memo/${USER}. Most distributions either have some automatic periodic cleanup, and/or wipe it on restart.

Separately from that:

```
- The invocation contains *memo* right in there, so you (the user) knows that it might memoize.
- One uses memo(1) for commands that are generally slow. Rerunning your command that has a slow part and having it return in a millisecond while you weren't expecting it should make the spider-sense tingle.
```
In practice, this has never been a problem for me, and I've used this hacked together command for years.
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45687095() async throws {
        let html = #"""
<p>The name of the memo is the command that comes after it:<p><pre><code>  $ memo my-complex-command --some-flag my-positional-arg-1
</code></pre>
In this invocation, a hash (sha512) is taken of &quot;my-complex-command --some-flag my-positional-arg-1&quot;, which is then stored in &#x2F;tmp&#x2F;memo&#x2F;${USER}&#x2F;{sha512hash}.zst (if you&#x27;ve got zstd installed, other compression extensions otherwise).
"""#
        let expected = #"""
The name of the memo is the command that comes after it:

```
$ memo my-complex-command --some-flag my-positional-arg-1
```
In this invocation, a hash (sha512) is taken of "my-complex-command --some-flag my-positional-arg-1", which is then stored in /tmp/memo/${USER}/{sha512hash}.zst (if you've got zstd installed, other compression extensions otherwise).
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45687200() async throws {
        let html = #"""
<p>Yes, I know. I should&#x27;ve taken a different example. But it&#x27;s also realistic in a way. When I&#x27;m doing one-offs, I will sometimes take shortcuts like this. I know awk fairly well, and I know enough of jq that I know invoking <i>jq .</i> pretty prints the inbound json on multiple lines. While I know I could create a proper jq expression, the combo will get me there quicker. Similarly I&#x27;ll sometimes do:<p><pre><code>  $ awk &#x27;...&#x27; | grep | ...
</code></pre>
Because I&#x27;m too lazy to go back to the start of the awk invocation and add a match condition there. If I&#x27;m going to save it to a script, I&#x27;ll clean it up. (And for jq, I gotta be honest that my starting point these days would probably be to show my contraption to an LLM and use its answer as a starting point, I don&#x27;t use jq nearly enough to learn its language by memory.)
"""#
        let expected = #"""
Yes, I know. I should've taken a different example. But it's also realistic in a way. When I'm doing one-offs, I will sometimes take shortcuts like this. I know awk fairly well, and I know enough of jq that I know invoking *jq .* pretty prints the inbound json on multiple lines. While I know I could create a proper jq expression, the combo will get me there quicker. Similarly I'll sometimes do:

```
$ awk '...' | grep | ...
```
Because I'm too lazy to go back to the start of the awk invocation and add a match condition there. If I'm going to save it to a script, I'll clean it up. (And for jq, I gotta be honest that my starting point these days would probably be to show my contraption to an LLM and use its answer as a starting point, I don't use jq nearly enough to learn its language by memory.)
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45674729() async throws {
        let html = #"""
<p>Python also pretty-prints out of the box:<p><pre><code>    $ echo &#x27;{ &quot;hello&quot;: &quot;world&quot; }&#x27; | python3 -m json.tool
    {
        &quot;hello&quot;: &quot;world&quot;
    }</code></pre>
"""#
        let expected = #"""
Python also pretty-prints out of the box:

```
$ echo '{ "hello": "world" }' | python3 -m json.tool
{
    "hello": "world"
}
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45676857() async throws {
        let html = #"""
<p>Other examples where native features are better than these self-made scripts...<p>&gt; vim [...] I select a region and then run :&#x27;&lt;,&#x27;&gt;!markdownquote<p>Just select the first column with ctrl-v, then &quot;i&gt; &quot; then escape. That&#x27;s 4 keys after the selection, instead of 20.<p>&gt; u+ 2025 returns ñ, LATIN SMALL LETTER N WITH TILDE<p>`unicode` is widely available, has a good default search, and many options.
BTW, I wonder why &quot;2025&quot; matched &quot;ñ&quot;.<p><pre><code>     unicode ñ
    U+00F1 LATIN SMALL LETTER N WITH TILDE
    UTF-8: c3 b1 UTF-16BE: 00f1 Decimal: &amp;#241; Octal: \0361
</code></pre>
&gt; catbin foo is basically cat &quot;$(which foo)&quot;<p>Since the author is using zsh, `cat =foo` is shorter and more powerful. It&#x27;s also much less error-prone with long commands, since zsh can smartly complete after =.<p>I use it often, e.g. `file =firefox` or `vim =myscript.sh`.
"""#
        let expected = #"""
Other examples where native features are better than these self-made scripts...

> vim [...] I select a region and then run :'<,'>!markdownquote

Just select the first column with ctrl-v, then "i> " then escape. That's 4 keys after the selection, instead of 20.

> u+ 2025 returns ñ, LATIN SMALL LETTER N WITH TILDE

`unicode` is widely available, has a good default search, and many options.
BTW, I wonder why "2025" matched "ñ".

```
unicode ñ
U+00F1 LATIN SMALL LETTER N WITH TILDE
UTF-8: c3 b1 UTF-16BE: 00f1 Decimal: ñ Octal: \0361
```
> catbin foo is basically cat "$(which foo)"

Since the author is using zsh, `cat =foo` is shorter and more powerful. It's also much less error-prone with long commands, since zsh can smartly complete after =.

I use it often, e.g. `file =firefox` or `vim =myscript.sh`.
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45681799() async throws {
        let html = #"""
<p>You are right but<p><pre><code>  $ unicode
  Command &#x27;unicode&#x27; not found, but can be installed with:
  sudo apt install unicode
</code></pre>
and it did. So it really was available. That&#x27;s Debian 11.
"""#
        let expected = #"""
You are right but

```
$ unicode
Command 'unicode' not found, but can be installed with:
sudo apt install unicode
```
and it did. So it really was available. That's Debian 11.
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45674987() async throws {
        let html = #"""
<p>&gt; Why prioritise node instead of jq?<p>In powershell I just do<p><pre><code>    &gt; echo &#x27;{&quot;foo&quot;: &quot;bar&quot;} | ConvertFrom-Json | ConvertTo-Json
    {
        &quot;foo&quot;: &quot;bar&quot;
    }
</code></pre>
But as a function
"""#
        let expected = #"""
> Why prioritise node instead of jq?

In powershell I just do

```
> echo '{"foo": "bar"} | ConvertFrom-Json | ConvertTo-Json
{
    "foo": "bar"
}
```
But as a function
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45685373() async throws {
        let html = #"""
<p>On Linux you also have<p><pre><code>    % cat &#x2F;proc&#x2F;sys&#x2F;kernel&#x2F;random&#x2F;uuid
    464a4e91-5ce4-47b6-bb09-8a60fde572fb</code></pre>
"""#
        let expected = #"""
On Linux you also have

```
% cat /proc/sys/kernel/random/uuid
464a4e91-5ce4-47b6-bb09-8a60fde572fb
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45680042() async throws {
        let html = #"""
<p><pre><code>    &gt;YOU DON&#x27;T UNDERSTAND. I NEED TO BE CONSTANTLY OPTIMIZING MY UPTIME. THE SCIENCE DEMANDS IT. TIMEMAXXING. I CAN&#x27;T FREELY EXPLORE OR BRAINSTORM, IT&#x27;S NOT XKCD 1205 COMPLIANT. I MUST EVALUATE EVERY PROPOSED ACTIVITY AGAINST THE TIME-OPTIMIZATION-PIVOT-TABLE.</code></pre>
"""#
        let expected = #"""
```
>YOU DON'T UNDERSTAND. I NEED TO BE CONSTANTLY OPTIMIZING MY UPTIME. THE SCIENCE DEMANDS IT. TIMEMAXXING. I CAN'T FREELY EXPLORE OR BRAINSTORM, IT'S NOT XKCD 1205 COMPLIANT. I MUST EVALUATE EVERY PROPOSED ACTIVITY AGAINST THE TIME-OPTIMIZATION-PIVOT-TABLE.
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45680256() async throws {
        let html = #"""
<p>I&#x27;ve written on this before, but I have an extensive collection of &quot;at&quot; scripts. This started 25+ years ago when I dragged a PC tower running BSD to a friend&#x27;s house, and their network differed from mine. So I wrote an @friend script which did a bunch of ifconfig foo.<p>Over time that&#x27;s grown to an @foo script for every project I work on, every place I frequent that has some kind of specific setup. They are prefixed with an @ because that only rarely conflicts with anything, and tab-complete helps me remember the less frequently used ones.<p>The @project scripts setup the whole environment, alias the appropriate build tools and versions of those tools, prepare the correct IDE config if needed, drop me in the project&#x27;s directory, etc. Some start a VPN connection because some of my clients only have git access over VPN etc.<p>Because I&#x27;ve worked on many things over many years, most of these scripts also output some &quot;help&quot; output so I can remember how shit works for a given project.<p>Here&#x27;s an example:<p><pre><code>    # @foo
    
    PROJECT FOO
    -----------
    
    VPN Connection: active, split tunnel
    
    Commands: 
    tests: mvn clean verify -P local_tests
    build all components: buildall
    
    Tools:
    java version: 17.0.16-tem
    maven version: 3.9.11
</code></pre>
Edit: a word on aliases, I frequently alias tools like maven or ansible to include config files that are specific to that project. That way I can have a .m2 folder for every project that doesn&#x27;t get polluted by other projects, I don&#x27;t have to remember to tell ansible which inventory file to use, etc. I&#x27;m lazy and my memory is for shit.
"""#
        let expected = #"""
I've written on this before, but I have an extensive collection of "at" scripts. This started 25+ years ago when I dragged a PC tower running BSD to a friend's house, and their network differed from mine. So I wrote an @friend script which did a bunch of ifconfig foo.

Over time that's grown to an @foo script for every project I work on, every place I frequent that has some kind of specific setup. They are prefixed with an @ because that only rarely conflicts with anything, and tab-complete helps me remember the less frequently used ones.

The @project scripts setup the whole environment, alias the appropriate build tools and versions of those tools, prepare the correct IDE config if needed, drop me in the project's directory, etc. Some start a VPN connection because some of my clients only have git access over VPN etc.

Because I've worked on many things over many years, most of these scripts also output some "help" output so I can remember how shit works for a given project.

Here's an example:

```
# @foo
PROJECT FOO
-----------
VPN Connection: active, split tunnel
Commands: 
tests: mvn clean verify -P local_tests
build all components: buildall
Tools:
java version: 17.0.16-tem
maven version: 3.9.11
```

Edit: a word on aliases, I frequently alias tools like maven or ansible to include config files that are specific to that project. That way I can have a .m2 folder for every project that doesn't get polluted by other projects, I don't have to remember to tell ansible which inventory file to use, etc. I'm lazy and my memory is for shit.
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45672747() async throws {
        let html = #"""
<p>Regarding the `line` script, just a note that sed can print an arbitrary line from a file, no need to invoke a pipeline of cat, head, and tail:<p><pre><code>    sed -n 2p file
</code></pre>
prints the second line of file. The advantage sed has over this line script is it can also print more than one line, should you need to:<p><pre><code>    sed -n 2,4p file
</code></pre>
prints lines 2 through 4, inclusive.
"""#
        let expected = #"""
Regarding the `line` script, just a note that sed can print an arbitrary line from a file, no need to invoke a pipeline of cat, head, and tail:

```
sed -n 2p file
```
prints the second line of file. The advantage sed has over this line script is it can also print more than one line, should you need to:

```
sed -n 2,4p file
```
prints lines 2 through 4, inclusive.
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45674999() async throws {
        let html = #"""
<p>My fav script to unpack anything, found a few years ago somewhere<p><pre><code>      # ex - archive extractor
      # usage: ex &lt;file&gt;
      function ex() {
          if [ -f $1 ] ; then
          case $1 in
              *.tar.bz2) tar xjf $1 ;;
              *.tar.gz) tar xzf $1 ;;
              *.tar.xz) tar xf $1 ;;
              *.bz2) bunzip2 $1 ;;
              *.rar) unrar x $1 ;;
              *.gz) gunzip $1 ;;
              *.tar) tar xf $1 ;;
              *.tbz2) tar xjf $1 ;;
              *.tgz) tar xzf $1 ;;
              *.zip) unzip $1 ;;
              *.Z) uncompress $1;;
              *.7z) 7z x $1 ;;
              *) echo &quot;&#x27;$1&#x27; cannot be extracted via ex()&quot; ;;
          esac
          else
              echo &quot;&#x27;$1&#x27; is not a valid file&quot;
          fi
      }</code></pre>
"""#
        let expected = #"""
My fav script to unpack anything, found a few years ago somewhere

```
# ex - archive extractor
# usage: ex <file>
function ex() {
    if [ -f $1 ] ; then
    case $1 in
        *.tar.bz2) tar xjf $1 ;;
        *.tar.gz) tar xzf $1 ;;
        *.tar.xz) tar xf $1 ;;
        *.bz2) bunzip2 $1 ;;
        *.rar) unrar x $1 ;;
        *.gz) gunzip $1 ;;
        *.tar) tar xf $1 ;;
        *.tbz2) tar xjf $1 ;;
        *.tgz) tar xzf $1 ;;
        *.zip) unzip $1 ;;
        *.Z) uncompress $1;;
        *.7z) 7z x $1 ;;
        *) echo "'$1' cannot be extracted via ex()" ;;
    esac
    else
        echo "'$1' is not a valid file"
    fi
}
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45690508() async throws {
        let html = #"""
<p>I had found a zsh version somewhere which I&#x27;ve updated a few times over the years though I don&#x27;t get a chance to use it much. :&#x27;D<p><pre><code>    un () {
 unsetopt extendedglob
 local old_dirs current_dirs lower do_cd
 if [ -z &quot;$1&quot; ]
 then
  print &quot;Must supply an archive argument.&quot;
  return 1
 fi
 if [ -d &quot;$1&quot; ]
 then
  print &quot;Can&#x27;t do much with directory arguments.&quot;
  return 1
 fi
 if [ ! -e &quot;$1&quot; -a ! -h &quot;$1&quot; ]
 then
  print &quot;$1 does not exist.&quot;
  return 1
 fi
 if [ ! -r &quot;$1&quot; ]
 then
  print &quot;$1 is not readable.&quot;
  return 1
 fi
 do_cd=1 
 lower=&quot;${(L)1}&quot; 
 old_dirs=(*(N&#x2F;)) 
 undone=false 
 if which unar &gt; &#x2F;dev&#x2F;null 2&gt;&amp;1 &amp;&amp; unar &quot;$1&quot;
 then
  undone=true 
 fi
 if ! $undone
 then
  INFO=&quot;$(file &quot;$1&quot;)&quot; 
  INFO=&quot;${INFO##*: }&quot; 
  if command grep -a --line-buffered --color=auto -E &quot;Zstandard compressed data&quot; &gt; &#x2F;dev&#x2F;null &lt;&lt;&lt; &quot;$INFO&quot;
  then
   zstd -T0 -d &quot;$1&quot;
  elif command grep -a --line-buffered --color=auto -E &quot;bzip2 compressed&quot; &gt; &#x2F;dev&#x2F;null &lt;&lt;&lt; &quot;$INFO&quot;
  then
   bunzip2 -kv &quot;$1&quot;
  elif command grep -a --line-buffered --color=auto -E &quot;Zip archive&quot; &gt; &#x2F;dev&#x2F;null &lt;&lt;&lt; &quot;$INFO&quot;
  then
   unzip &quot;$1&quot;
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E &quot;RAR archive&quot; &gt; &#x2F;dev&#x2F;null
  then
   unrar e &quot;$1&quot;
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E &#x27;xar archive&#x27; &gt; &#x2F;dev&#x2F;null
  then
   xar -xvf &quot;$1&quot;
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E -i &quot;tar archive&quot; &gt; &#x2F;dev&#x2F;null
  then
   if which gtar &gt; &#x2F;dev&#x2F;null 2&gt;&amp;1
   then
    gtar xvf &quot;$1&quot;
   else
    tar xvf &quot;$1&quot;
   fi
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E -i &quot;LHa&quot; &gt; &#x2F;dev&#x2F;null
  then
   lha e &quot;$1&quot;
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E -i &quot;LHa&quot; &gt; &#x2F;dev&#x2F;null
  then
   lha e &quot;$1&quot;
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E &quot;compress&#x27;d&quot; &gt; &#x2F;dev&#x2F;null
  then
   uncompress -c &quot;$1&quot;
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E &quot;xz compressed&quot; &gt; &#x2F;dev&#x2F;null
  then
   unxz -k &quot;$1&quot;
   do_cd=0 
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E &quot;7-zip&quot; &gt; &#x2F;dev&#x2F;null
  then
   7z x &quot;$1&quot;
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E &quot;RPM &quot; &gt; &#x2F;dev&#x2F;null
  then
   if [ &quot;$osname&quot; = &quot;Darwin&quot; ]
   then
    rpm2cpio &quot;$1&quot; | cpio -i -d --quiet
   else
    rpm2cpio &quot;$1&quot; | cpio -i --no-absolute-filenames -d --quiet
   fi
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E &quot;cpio archive&quot; &gt; &#x2F;dev&#x2F;null
  then
   cpio -i --no-absolute-filenames -d --quiet &lt; &quot;$1&quot;
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E &quot;Debian .* package&quot; &gt; &#x2F;dev&#x2F;null
  then
   dpkg-deb -x &quot;$1&quot; .
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E -i &quot; ar archive&quot; &gt; &#x2F;dev&#x2F;null
  then
   ar x &quot;$1&quot;
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E -i &quot;ACE archive&quot; &gt; &#x2F;dev&#x2F;null
  then
   unace e &quot;$1&quot;
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E -i &quot;ARJ archive&quot; &gt; &#x2F;dev&#x2F;null
  then
   arj e &quot;$1&quot;
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E -i &quot;xar archive&quot; &gt; &#x2F;dev&#x2F;null
  then
   xar -xvf &quot;$1&quot;
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E -i &quot;ZOO archive&quot; &gt; &#x2F;dev&#x2F;null
  then
   zoo x &quot;$1&quot;
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E -Ei &quot;(tnef|Transport Neutral Encapsulation Format)&quot; &gt; &#x2F;dev&#x2F;null
  then
   tnef &quot;$1&quot;
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E -i &quot;InstallShield CAB&quot; &gt; &#x2F;dev&#x2F;null
  then
   unshield x &quot;$1&quot;
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E -Ei &quot;(mail|news)&quot; &gt; &#x2F;dev&#x2F;null
  then
   formail -s munpack &lt; &quot;$1&quot;
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E -i &quot;uuencode&quot; &gt; &#x2F;dev&#x2F;null
  then
   uudecode &quot;$1&quot;
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E -i &quot;cab&quot; &gt; &#x2F;dev&#x2F;null
  then
   cabextract &quot;$1&quot;
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E -i &quot;PPMD archive&quot; &gt; &#x2F;dev&#x2F;null
  then
   ln -s &quot;$1&quot; . &amp;&amp; ppmd d &quot;$1&quot; &amp;&amp; rm `basename &quot;$1&quot;`
  elif [[ $lower == *.zst ]]
  then
   zstd -T0 -d &quot;$1&quot;
  elif [[ $lower == *.bz2 ]]
  then
   bunzip2 -kv &quot;$1&quot;
  elif [[ $lower == *.zip ]]
  then
   unzip &quot;$1&quot;
  elif [[ $lower == *.jar ]]
  then
   unzip &quot;$1&quot;
  elif [[ $lower == *.xpi ]]
  then
   unzip &quot;$1&quot;
  elif [[ $lower == *.rar ]]
  then
   unrar e &quot;$1&quot;
  elif [[ $lower == *.xar ]]
  then
   xar -xvf &quot;$1&quot;
  elif [[ $lower == *.pkg ]]
  then
   xar -xvf &quot;$1&quot;
  elif [[ $lower == *.tar ]]
  then
   if which gtar &gt; &#x2F;dev&#x2F;null 2&gt;&amp;1
   then
    gtar xvf &quot;$1&quot;
   else
    tar xvf &quot;$1&quot;
   fi
  elif [[ $lower == *.tar.zst || $lower == *.tzst ]]
  then
   which gtar &gt; &#x2F;dev&#x2F;null 2&gt;&amp;1
   if [[ $? == 0 ]]
   then
    gtar -xv -I &#x27;zstd -T0 -v&#x27; -f &quot;$1&quot;
   elif [[ ${OSTYPE:l} == linux* ]]
   then
    tar -xv -I &#x27;zstd -T0 -v&#x27; -f &quot;$1&quot;
   else
    zstd -d -v -T0 -c &quot;$1&quot; | tar xvf -
   fi
  elif [[ $lower == *.tar.gz || $lower == *.tgz ]]
  then
   which gtar &gt; &#x2F;dev&#x2F;null 2&gt;&amp;1
   if [[ $? == 0 ]]
   then
    gtar zxfv &quot;$1&quot;
   elif [[ ${OSTYPE:l} == linux* ]]
   then
    tar zxfv &quot;$1&quot;
   else
    gunzip -c &quot;$1&quot; | tar xvf -
   fi
  elif [[ $lower == *.tar.z ]]
  then
   uncompress -c &quot;$1&quot; | tar xvf -
  elif [[ $lower == *.tar.xz || $lower == *.txz ]]
  then
   which gtar &gt; &#x2F;dev&#x2F;null 2&gt;&amp;1
   if [[ $? == 0 ]]
   then
    xzcat &quot;$1&quot; | gtar xvf -
   else
    xzcat &quot;$1&quot; | tar xvf -
   fi
  elif echo &quot;$INFO&quot; | command grep -a --line-buffered --color=auto -E &#x27;gzip compressed&#x27; &gt; &#x2F;dev&#x2F;null || [[ $lower == *.gz ]]
  then
   if [[ $lower == *.gz ]]
   then
    gzcat -d &quot;$1&quot; &gt; &quot;${1%.gz}&quot;
   else
    cat &quot;$1&quot; | gunzip -
   fi
   do_cd=0 
  elif [[ $lower == *.tar.bz2 || $lower == *.tbz ]]
  then
   bunzip2 -kc &quot;$1&quot; | tar xfv -
  elif [[ $lower == *.tar.lz4 ]]
  then
   local mytar
   if [[ -n &quot;$(command -v gtar)&quot; ]]
   then
    mytar=gtar 
   else
    mytar=tar 
   fi
   if [[ -n &quot;$(command -v lz4)&quot; ]]
   then
    $mytar -xv -I lz4 -f &quot;$1&quot;
   elif [[ -n &quot;$(command -v lz4cat)&quot; ]]
   then
    lz4cat -kd &quot;$1&quot; | $mytar xfv -
   else
    print &quot;Unknown archive type: $1&quot;
    return 1
   fi
  elif [[ $lower == *.lz4 ]]
  then
   lz4 -d &quot;$1&quot;
  elif [[ $lower == *.epub ]]
  then
   unzip &quot;$1&quot;
  elif [[ $lower == *.lha ]]
  then
   lha e &quot;$1&quot;
  elif which aunpack &gt; &#x2F;dev&#x2F;null 2&gt;&amp;1
  then
   aunpack &quot;$@&quot;
   return $?
  else
   print &quot;Unknown archive type: $1&quot;
   return 1
  fi
 fi
 if [[ $do_cd == 1 ]]
 then
  current_dirs=(*(N&#x2F;)) 
  for i in {1..${#current_dirs}}
  do
   if [[ $current_dirs[$i] != &quot;$old_dirs[$i]&quot; ]]
   then
    cd &quot;$current_dirs[$i]&quot;
    ls
    break
   fi
  done
 fi
    }</code></pre>
"""#
        let expected = #"""
I had found a zsh version somewhere which I've updated a few times over the years though I don't get a chance to use it much. :'D

```
un () {
unsetopt extendedglob
local old_dirs current_dirs lower do_cd
if [ -z "$1" ]
then
print "Must supply an archive argument."
return 1
fi
if [ -d "$1" ]
then
print "Can't do much with directory arguments."
return 1
fi
if [ ! -e "$1" -a ! -h "$1" ]
then
print "$1 does not exist."
return 1
fi
if [ ! -r "$1" ]
then
print "$1 is not readable."
return 1
fi
do_cd=1 
lower="${(L)1}" 
old_dirs=(*(N/)) 
undone=false 
if which unar > /dev/null 2>&1 && unar "$1"
then
undone=true 
fi
if ! $undone
then
INFO="$(file "$1")" 
INFO="${INFO##*: }" 
if command grep -a --line-buffered --color=auto -E "Zstandard compressed data" > /dev/null <<< "$INFO"
then
zstd -T0 -d "$1"
elif command grep -a --line-buffered --color=auto -E "bzip2 compressed" > /dev/null <<< "$INFO"
then
bunzip2 -kv "$1"
elif command grep -a --line-buffered --color=auto -E "Zip archive" > /dev/null <<< "$INFO"
then
unzip "$1"
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E "RAR archive" > /dev/null
then
unrar e "$1"
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E 'xar archive' > /dev/null
then
xar -xvf "$1"
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E -i "tar archive" > /dev/null
then
if which gtar > /dev/null 2>&1
then
gtar xvf "$1"
else
tar xvf "$1"
fi
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E -i "LHa" > /dev/null
then
lha e "$1"
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E -i "LHa" > /dev/null
then
lha e "$1"
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E "compress'd" > /dev/null
then
uncompress -c "$1"
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E "xz compressed" > /dev/null
then
unxz -k "$1"
do_cd=0 
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E "7-zip" > /dev/null
then
7z x "$1"
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E "RPM " > /dev/null
then
if [ "$osname" = "Darwin" ]
then
rpm2cpio "$1" | cpio -i -d --quiet
else
rpm2cpio "$1" | cpio -i --no-absolute-filenames -d --quiet
fi
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E "cpio archive" > /dev/null
then
cpio -i --no-absolute-filenames -d --quiet < "$1"
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E "Debian .* package" > /dev/null
then
dpkg-deb -x "$1" .
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E -i " ar archive" > /dev/null
then
ar x "$1"
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E -i "ACE archive" > /dev/null
then
unace e "$1"
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E -i "ARJ archive" > /dev/null
then
arj e "$1"
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E -i "xar archive" > /dev/null
then
xar -xvf "$1"
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E -i "ZOO archive" > /dev/null
then
zoo x "$1"
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E -Ei "(tnef|Transport Neutral Encapsulation Format)" > /dev/null
then
tnef "$1"
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E -i "InstallShield CAB" > /dev/null
then
unshield x "$1"
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E -Ei "(mail|news)" > /dev/null
then
formail -s munpack < "$1"
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E -i "uuencode" > /dev/null
then
uudecode "$1"
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E -i "cab" > /dev/null
then
cabextract "$1"
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E -i "PPMD archive" > /dev/null
then
ln -s "$1" . && ppmd d "$1" && rm `basename "$1"`
elif [[ $lower == *.zst ]]
then
zstd -T0 -d "$1"
elif [[ $lower == *.bz2 ]]
then
bunzip2 -kv "$1"
elif [[ $lower == *.zip ]]
then
unzip "$1"
elif [[ $lower == *.jar ]]
then
unzip "$1"
elif [[ $lower == *.xpi ]]
then
unzip "$1"
elif [[ $lower == *.rar ]]
then
unrar e "$1"
elif [[ $lower == *.xar ]]
then
xar -xvf "$1"
elif [[ $lower == *.pkg ]]
then
xar -xvf "$1"
elif [[ $lower == *.tar ]]
then
if which gtar > /dev/null 2>&1
then
gtar xvf "$1"
else
tar xvf "$1"
fi
elif [[ $lower == *.tar.zst || $lower == *.tzst ]]
then
which gtar > /dev/null 2>&1
if [[ $? == 0 ]]
then
gtar -xv -I 'zstd -T0 -v' -f "$1"
elif [[ ${OSTYPE:l} == linux* ]]
then
tar -xv -I 'zstd -T0 -v' -f "$1"
else
zstd -d -v -T0 -c "$1" | tar xvf -
fi
elif [[ $lower == *.tar.gz || $lower == *.tgz ]]
then
which gtar > /dev/null 2>&1
if [[ $? == 0 ]]
then
gtar zxfv "$1"
elif [[ ${OSTYPE:l} == linux* ]]
then
tar zxfv "$1"
else
gunzip -c "$1" | tar xvf -
fi
elif [[ $lower == *.tar.z ]]
then
uncompress -c "$1" | tar xvf -
elif [[ $lower == *.tar.xz || $lower == *.txz ]]
then
which gtar > /dev/null 2>&1
if [[ $? == 0 ]]
then
xzcat "$1" | gtar xvf -
else
xzcat "$1" | tar xvf -
fi
elif echo "$INFO" | command grep -a --line-buffered --color=auto -E 'gzip compressed' > /dev/null || [[ $lower == *.gz ]]
then
if [[ $lower == *.gz ]]
then
gzcat -d "$1" > "${1%.gz}"
else
cat "$1" | gunzip -
fi
do_cd=0 
elif [[ $lower == *.tar.bz2 || $lower == *.tbz ]]
then
bunzip2 -kc "$1" | tar xfv -
elif [[ $lower == *.tar.lz4 ]]
then
local mytar
if [[ -n "$(command -v gtar)" ]]
then
mytar=gtar 
else
mytar=tar 
fi
if [[ -n "$(command -v lz4)" ]]
then
$mytar -xv -I lz4 -f "$1"
elif [[ -n "$(command -v lz4cat)" ]]
then
lz4cat -kd "$1" | $mytar xfv -
else
print "Unknown archive type: $1"
return 1
fi
elif [[ $lower == *.lz4 ]]
then
lz4 -d "$1"
elif [[ $lower == *.epub ]]
then
unzip "$1"
elif [[ $lower == *.lha ]]
then
lha e "$1"
elif which aunpack > /dev/null 2>&1
then
aunpack "$@"
return $?
else
print "Unknown archive type: $1"
return 1
fi
fi
if [[ $do_cd == 1 ]]
then
current_dirs=(*(N/)) 
for i in {1..${#current_dirs}}
do
if [[ $current_dirs[$i] != "$old_dirs[$i]" ]]
then
cd "$current_dirs[$i]"
ls
break
fi
done
fi
}
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45675495() async throws {
        let html = #"""
<p>While you&#x27;re creating and testing aliases, it&#x27;s handy to source your ~&#x2F;.zshrc whenever you edit it:<p><pre><code>    alias vz=&quot;vim ~&#x2F;.zshrc &amp;&amp; . ~&#x2F;.zshrc&quot;
</code></pre>
I alias mdfind to grep my .docx files on my Mac:<p><pre><code>    docgrep() {
      mdfind &quot;\&quot;$@\&quot;&quot; -onlyin &#x2F;Users&#x2F;xxxx&#x2F;Notes 2&gt; &gt;(grep --invert-match &#x27; \[UserQueryParser\] &#x27; &gt;&amp;2) | grep -v -e &#x27;&#x2F;Inactive&#x2F;&#x27; | sort
    }
</code></pre>
I use an `anon` function to anonymize my Mac clipboard when I want to paste something to the public ChatGPT, company Slack, private notes, etc. I ran it through itself before pasting it here, for example.<p><pre><code>    anonymizeclipboard() {
      my_user_id=xxxx
      account_ids=&quot;1234567890|1234567890&quot;  #regex
      corp_words=&quot;xxxx|xxxx|xxxx|xxxx|xxxx&quot;  #regex
      project_names=&quot;xxxx|xxxx|xxxx|xxxx|xxxx&quot;  # regex
      pii=&quot;xxxx|xxxx|xxxx|xxxx|xxxx|xxxx&quot;  # regex
      hostnames=&quot;xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx&quot;  # regex
      # anonymize IPs
      pbpaste | sed -E -e &#x27;s&#x2F;([0-9]{1,3})\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}&#x2F;\1.x.x.x&#x2F;g&#x27; \
      -e &quot;s&#x2F;(${corp_words}|${project_names}|${my_user_id}|${pii}|${hostnames})&#x2F;xxxx&#x2F;g&quot; -e &quot;s&#x2F;(${account_ids})&#x2F;1234567890&#x2F;g&quot; | pbcopy
      pbpaste
    }

    alias anon=anonymizeclipboard
</code></pre>
It prints the new clipboard to stdout so you can inspect what you&#x27;ll be pasting for anything it missed.
"""#
        let expected = #"""
While you're creating and testing aliases, it's handy to source your ~/.zshrc whenever you edit it:

```
alias vz="vim ~/.zshrc && . ~/.zshrc"
```
I alias mdfind to grep my .docx files on my Mac:

```
docgrep() {
  mdfind "\"$@\"" -onlyin /Users/xxxx/Notes 2> >(grep --invert-match ' \[UserQueryParser\] ' >&2) | grep -v -e '/Inactive/' | sort
}
```
I use an `anon` function to anonymize my Mac clipboard when I want to paste something to the public ChatGPT, company Slack, private notes, etc. I ran it through itself before pasting it here, for example.

```
anonymizeclipboard() {
  my_user_id=xxxx
  account_ids="1234567890|1234567890"  #regex
  corp_words="xxxx|xxxx|xxxx|xxxx|xxxx"  #regex
  project_names="xxxx|xxxx|xxxx|xxxx|xxxx"  # regex
  pii="xxxx|xxxx|xxxx|xxxx|xxxx|xxxx"  # regex
  hostnames="xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx|xxxx"  # regex
  # anonymize IPs
  pbpaste | sed -E -e 's/([0-9]{1,3})\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/\1.x.x.x/g' \
  -e "s/(${corp_words}|${project_names}|${my_user_id}|${pii}|${hostnames})/xxxx/g" -e "s/(${account_ids})/1234567890/g" | pbcopy
  pbpaste
}
alias anon=anonymizeclipboard
```
It prints the new clipboard to stdout so you can inspect what you'll be pasting for anything it missed.
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45675856() async throws {
        let html = #"""
<p>I use these two all the time to encode and cut mp4s.<p>The flags are for maximum compatibility (e.g. without them, some MP4s don&#x27;t play in WhatsApp, or Discord on mobile, or whatever.)<p><pre><code>    ffmp4() {
        input_file=&quot;$1&quot;
        output_file=&quot;${input_file%.*}_sd.mp4&quot;

        ffmpeg -i &quot;$input_file&quot; -c:v libx264 -crf 33 -profile:v baseline -level 3.0 -pix_fmt yuv420p -movflags faststart &quot;$output_file&quot;

        echo &quot;Compressed video saved as: $output_file&quot;
    }
    
    </code></pre>
ffmp4 foo.webm<p>-&gt; foo_sd.mp4<p><pre><code>    fftime() {
        input_file=&quot;$1&quot;
        output_file=&quot;${input_file%.*}_cut.mp4&quot;
        ffmpeg -i &quot;$input_file&quot; -c copy -ss &quot;$2&quot; -to &quot;$3&quot; &quot;$output_file&quot;

        echo &quot;Cut video saved as: $output_file&quot;
    }

</code></pre>
fftime foo.mp4 01:30 01:45<p>-&gt; foo_cut.mp4<p>Note, fftime copies the audio and video data without re-encoding, which can be a little janky, but often works fine, and can be much (100x) faster on large files. To re-encode just remove &quot;-c copy&quot;
"""#
        let expected = #"""
I use these two all the time to encode and cut mp4s.

The flags are for maximum compatibility (e.g. without them, some MP4s don't play in WhatsApp, or Discord on mobile, or whatever.)

```
ffmp4() {
    input_file="$1"
    output_file="${input_file%.*}_sd.mp4"
    ffmpeg -i "$input_file" -c:v libx264 -crf 33 -profile:v baseline -level 3.0 -pix_fmt yuv420p -movflags faststart "$output_file"
    echo "Compressed video saved as: $output_file"
}
```
ffmp4 foo.webm

-> foo_sd.mp4

```
fftime() {
    input_file="$1"
    output_file="${input_file%.*}_cut.mp4"
    ffmpeg -i "$input_file" -c copy -ss "$2" -to "$3" "$output_file"
    echo "Cut video saved as: $output_file"
}
```
fftime foo.mp4 01:30 01:45

-> foo_cut.mp4

Note, fftime copies the audio and video data without re-encoding, which can be a little janky, but often works fine, and can be much (100x) faster on large files. To re-encode just remove "-c copy"
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45676406() async throws {
        let html = #"""
<p>I&#x27;m kicking myself for not thinking of the `nato` script.<p>I tend to try to not get too used to custom &quot;helper&quot; scripts because I become incapacitated when working in other systems. Nevertheless, I really appreciate all these scripts if nothing else than to see what patterns other programmers pick up.<p>My only addition is a small `tplate` script that creates HTML, C, C++, Makefile, etc. &quot;template&quot; files to start a project. Kind of like a &quot;wizard setup&quot;.  e.g.<p><pre><code>  $ tplate c
  #include &lt;stdio.h&gt;
  #include &lt;stdlib.h&gt;
  int main(int argc, char **argv) {
  }
</code></pre>
And of course, three scripts `:q`, `:w` and `:wq` that get used surprisingly often:<p><pre><code>  $ cat :q
  #!&#x2F;bin&#x2F;bash
  echo &quot;you&#x27;re not in vim&quot;</code></pre>
"""#
        let expected = #"""
I'm kicking myself for not thinking of the `nato` script.

I tend to try to not get too used to custom "helper" scripts because I become incapacitated when working in other systems. Nevertheless, I really appreciate all these scripts if nothing else than to see what patterns other programmers pick up.

My only addition is a small `tplate` script that creates HTML, C, C++, Makefile, etc. "template" files to start a project. Kind of like a "wizard setup".  e.g.

```
$ tplate c
#include <stdio.h>
#include <stdlib.h>
int main(int argc, char **argv) {
}
```
And of course, three scripts `:q`, `:w` and `:wq` that get used surprisingly often:

```
$ cat :q
#!/bin/bash
echo "you're not in vim"
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45673933() async throws {
        let html = #"""
<p>Obviously that script is more convenient, but if you’re on a system where you don’t have it, you can do the following instead:<p><pre><code>    mkdir &#x2F;some&#x2F;dir    
    cd !$   
    (or cd &lt;alt+.&gt;)</code></pre>
"""#
        let expected = #"""
Obviously that script is more convenient, but if you’re on a system where you don’t have it, you can do the following instead:

```
mkdir /some/dir    
cd !$   
(or cd <alt+.>)
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45678272() async throws {
        let html = #"""
<p>I too have a `mkcd` in my .zshrc, but I implemented it slightly differently:<p><pre><code>  function mkcd {
    newdir=$1
    mkdir -p $newdir
    cd $newdir
  }</code></pre>
"""#
        let expected = #"""
I too have a `mkcd` in my .zshrc, but I implemented it slightly differently:

```
function mkcd {
  newdir=$1
  mkdir -p $newdir
  cd $newdir
}
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45679922() async throws {
        let html = #"""
<p>One more from me:<p><pre><code>  mkcd() {
    mkdir -p -- &quot;$1&quot; &amp;&amp;
    cd -- &quot;$1&quot;
  }</code></pre>
"""#
        let expected = #"""
One more from me:

```
mkcd() {
  mkdir -p -- "$1" &&
  cd -- "$1"
}
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45674207() async throws {
        let html = #"""
<p>I keep meaning to generalize this (directory target, multiple sources, flags), but I get quite a bit of mileage out of this `unmv` script even as it is:<p><pre><code>  #!&#x2F;bin&#x2F;sh
  if test &quot;$#&quot; != 2
  then
      echo &#x27;Error: unmv must have exactly 2 arguments&#x27;
      exit 1
  fi
  exec mv &quot;$2&quot; &quot;$1&quot;</code></pre>
"""#
        let expected = #"""
I keep meaning to generalize this (directory target, multiple sources, flags), but I get quite a bit of mileage out of this `unmv` script even as it is:

```
#!/bin/sh
if test "$#" != 2
then
    echo 'Error: unmv must have exactly 2 arguments'
    exit 1
fi
exec mv "$2" "$1"
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45678770() async throws {
        let html = #"""
<p>One script I use quite often:<p><pre><code>    function unix() {
      if [ $# -gt 0 ]; then
        echo &quot;Arg: $(date -r &quot;$1&quot;)&quot;
      fi
      echo &quot;Now: $(date) - $(date +%s)&quot;
    }
</code></pre>
Prints the current date as UNIX timestamp. If you provide a UNIX timestamp as arg, it prints the arg as human readable date.
"""#
        let expected = #"""
One script I use quite often:

```
function unix() {
  if [ $# -gt 0 ]; then
    echo "Arg: $(date -r "$1")"
  fi
  echo "Now: $(date) - $(date +%s)"
}
```
Prints the current date as UNIX timestamp. If you provide a UNIX timestamp as arg, it prints the arg as human readable date.
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45685447() async throws {
        let html = #"""
<p>Similarly I have for Linux<p><pre><code>    epoch () {
        if [[ -z &quot;${1:-}&quot; ]]
        then
                date +&#x27;%s&#x27;
        else
                date --date=&quot;@${1}&quot;
        fi
    }

    % epoch
    1761245789

    % epoch 1761245789
    Thu Oct 23 11:56:29 PDT 2025</code></pre>
"""#
        let expected = #"""
Similarly I have for Linux

```
epoch () {
    if [[ -z "${1:-}" ]]
    then
            date +'%s'
    else
            date --date="@${1}"
    fi
}
% epoch
1761245789
% epoch 1761245789
Thu Oct 23 11:56:29 PDT 2025
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45676608() async throws {
        let html = #"""
<p>A few I use are:<p><pre><code>    #!&#x2F;usr&#x2F;bin&#x2F;env bash
    # ~&#x2F;bin&#x2F;,dehex

    echo &quot;$1&quot; | xxd -r -p

</code></pre>
and<p><pre><code>    #!&#x2F;usr&#x2F;bin&#x2F;env bash
    # ~&#x2F;bin&#x2F;,ht

    highlight() {
      # Foreground:
      # 30:black, 31:red, 32:green, 33:yellow, 34:blue, 35:magenta, 36:cyan

      # Background:
      # 40:black, 41:red, 42:green, 43:yellow, 44:blue, 45:magenta, 46:cyan
      escape=$(printf &#x27;\033&#x27;)
      sed &quot;s,$2,${escape}[$1m&amp;${escape}[0m,g&quot;
    }

    if [[ $# == 1 ]]; then
      highlight 31 $1
    elif [[ $# == 2 ]]; then
      highlight 31 $1 | highlight 32 $2
    elif [[ $# == 3 ]]; then
      highlight 31 $1 | highlight 32 $2 | highlight 35 $3
    elif [[ $# == 4 ]]; then
      highlight 31 $1 | highlight 32 $2 | highlight 35 $3 | highlight 36 $4
    fi
</code></pre>
I also use the comma-command pattern where I prefix my personal scripts with a `,` which allows me to cycle between them fast etc.<p>One thing I have found that&#x27;s worth it is periodically running an aggregation on one&#x27;s history and purging old ones that I don&#x27;t use.
"""#
        let expected = #"""
A few I use are:

```
#!/usr/bin/env bash
# ~/bin/,dehex
echo "$1" | xxd -r -p
```
and

```
#!/usr/bin/env bash
# ~/bin/,ht
highlight() {
  # Foreground:
  # 30:black, 31:red, 32:green, 33:yellow, 34:blue, 35:magenta, 36:cyan
  # Background:
  # 40:black, 41:red, 42:green, 43:yellow, 44:blue, 45:magenta, 46:cyan
  escape=$(printf '\033')
  sed "s,$2,${escape}[$1m&${escape}[0m,g"
}
if [[ $# == 1 ]]; then
  highlight 31 $1
elif [[ $# == 2 ]]; then
  highlight 31 $1 | highlight 32 $2
elif [[ $# == 3 ]]; then
  highlight 31 $1 | highlight 32 $2 | highlight 35 $3
elif [[ $# == 4 ]]; then
  highlight 31 $1 | highlight 32 $2 | highlight 35 $3 | highlight 36 $4
fi
```
I also use the comma-command pattern where I prefix my personal scripts with a `,` which allows me to cycle between them fast etc.

One thing I have found that's worth it is periodically running an aggregation on one's history and purging old ones that I don't use.
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45679221() async throws {
        let html = #"""
<p>With `xsel --clipboard` (put that in an alias like `clip`), you can use the same thing to replace both `copy` and `pasta`:<p><pre><code>    # High level examples
    run_some_command | clip
    clip &gt; file_from_my_clipboard.txt
    
    # Copy a file&#x27;s contents
    clip &lt; file.txt

    # indent for markdown:
    $ clip|sed &#x27;s&#x2F;^&#x2F;    &#x2F;&#x27;|clip</code></pre>
"""#
        let expected = #"""
With `xsel --clipboard` (put that in an alias like `clip`), you can use the same thing to replace both `copy` and `pasta`:

```
# High level examples
run_some_command | clip
clip > file_from_my_clipboard.txt
# Copy a file's contents
clip < file.txt
# indent for markdown:
$ clip|sed 's/^/    /'|clip
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45688709() async throws {
        let html = #"""
<p>Something I&#x27;ve long appreciated is a little Perl script to compute statistics on piped in numbers, I find it great for getting quick summaries from report CSVs.<p><pre><code>    #!&#x2F;usr&#x2F;bin&#x2F;perl
    # http:&#x2F;&#x2F;stackoverflow.com&#x2F;a&#x2F;9790056
    use List::Util qw(max min sum);
    @a=();
    while(&lt;&gt;){
        $sqsum+=$_*$_;
        push(@a,$_)
    };
    $n=@a;
    $s=sum(@a);
    $a=$s&#x2F;@a;
    $m=max(@a);
    $mm=min(@a);
    $std=sqrt($sqsum&#x2F;$n-($s&#x2F;$n)*($s&#x2F;$n));
    $mid=int @a&#x2F;2;
    @srtd=sort @a;
    if(@a%2){
        $med=$srtd[$mid];
    }else{
        $med=($srtd[$mid-1]+$srtd[$mid])&#x2F;2;
    };
    print &quot;records:$n\nsum:$s\navg:$a\nstd:$std\nmed:$med\max:$m\nmin:$mm&quot;;</code></pre>
"""#
        let expected = #"""
Something I've long appreciated is a little Perl script to compute statistics on piped in numbers, I find it great for getting quick summaries from report CSVs.

```
#!/usr/bin/perl
# http://stackoverflow.com/a/9790056
use List::Util qw(max min sum);
@a=();
while(<>){
    $sqsum+=$_*$_;
    push(@a,$_)
};
$n=@a;
$s=sum(@a);
$a=$s/@a;
$m=max(@a);
$mm=min(@a);
$std=sqrt($sqsum/$n-($s/$n)*($s/$n));
$mid=int @a/2;
@srtd=sort @a;
if(@a%2){
    $med=$srtd[$mid];
}else{
    $med=($srtd[$mid-1]+$srtd[$mid])/2;
};
print "records:$n\nsum:$s\navg:$a\nstd:$std\nmed:$med\max:$m\nmin:$mm";
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45677391() async throws {
        let html = #"""
<p>I find that I like working with the directory stack and having a shortened version of the directory stack in the title bar, e.g. by modifying the stock Debian .bashrc<p><pre><code>  # If this is an xterm set the title to the directory stack
  case &quot;$TERM&quot; in
  xterm*|rxvt*)
      if [ -x ~&#x2F;bin&#x2F;shorten-ds.pl ]; then
    PS1=&quot;\[\e]0;\$(dirs -v | ~&#x2F;bin&#x2F;shorten-ds.pl)\a\]$PS1&quot;
      else
    PS1=&quot;\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h:   \w\a\]$PS1&quot;
      fi
      ;;
  \*)
      ;;
  esac
</code></pre>
The script shorten_ds.pl takes e.g.<p><pre><code>  0  &#x2F;var&#x2F;log&#x2F;apt
  1  ~&#x2F;Downloads
  2  ~
</code></pre>
and shortens it to:<p><pre><code>  0:apt 1:Downloads 2:~

  #!&#x2F;usr&#x2F;bin&#x2F;perl -w
  use strict;
  my @lines;
  while (&lt;&gt;) {
    chomp;
    s%^ (\d+)  %$1:%;
    s%:.*&#x2F;([^&#x2F;]+)$%:$1%;
    push @lines, $_
  }
  print join &#x27; &#x27;, @lines;

</code></pre>
That coupled with functions that take &#x27;u 2&#x27; as shorthand for &#x27;pushd +2&#x27; and
&#x27;o 2&#x27; for &#x27;popd +2&#x27; make for easy manipulation of the directory stack:<p><pre><code>  u() {
    if [[ $1 =~ ^[0-9]+$ ]]; then
      pushd &quot;+$1&quot;
    else
      pushd &quot;$@&quot;
    fi
  }

  o() {
    if [[ $1 =~ ^[0-9]+$ ]]; then
      popd &quot;+$1&quot;
    else
      popd &quot;$@&quot; # lazy way to cause an error
    fi
  }</code></pre>
"""#
        let expected = #"""
I find that I like working with the directory stack and having a shortened version of the directory stack in the title bar, e.g. by modifying the stock Debian .bashrc

```
# If this is an xterm set the title to the directory stack
case "$TERM" in
xterm*|rxvt*)
    if [ -x ~/bin/shorten-ds.pl ]; then
  PS1="\[\e]0;\$(dirs -v | ~/bin/shorten-ds.pl)\a\]$PS1"
    else
  PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h:   \w\a\]$PS1"
    fi
    ;;
\*)
    ;;
esac
```
The script shorten_ds.pl takes e.g.

```
0  /var/log/apt
1  ~/Downloads
2  ~
```
and shortens it to:

```
0:apt 1:Downloads 2:~
#!/usr/bin/perl -w
use strict;
my @lines;
while (<>) {
  chomp;
  s%^ (\d+)  %$1:%;
  s%:.*/([^/]+)$%:$1%;
  push @lines, $_
}
print join ' ', @lines;
```
That coupled with functions that take 'u 2' as shorthand for 'pushd +2' and
'o 2' for 'popd +2' make for easy manipulation of the directory stack:

```
u() {
  if [[ $1 =~ ^[0-9]+$ ]]; then
    pushd "+$1"
  else
    pushd "$@"
  fi
}
o() {
  if [[ $1 =~ ^[0-9]+$ ]]; then
    popd "+$1"
  else
    popd "$@" # lazy way to cause an error
  fi
}
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45674974() async throws {
        let html = #"""
<p>I like this one.<p><pre><code>  $ cat &#x2F;usr&#x2F;local&#x2F;bin&#x2F;awkmail
  #!&#x2F;bin&#x2F;gawk -f

  BEGIN { smtp=&quot;&#x2F;inet&#x2F;tcp&#x2F;0&#x2F;smtp.yourco.com&#x2F;25&quot;;
  ORS=&quot;\r\n&quot;; r=ARGV[1]; s=ARGV[2]; sbj=ARGV[3]; # &#x2F;bin&#x2F;awkmail to from subj &lt; in

  print &quot;helo &quot; ENVIRON[&quot;HOSTNAME&quot;]        |&amp; smtp;  smtp |&amp; getline j; print j
  print &quot;mail from:&quot; s                     |&amp; smtp;  smtp |&amp; getline j; print j
  if(match(r, &quot;,&quot;))
  {
   split(r, z, &quot;,&quot;)
   for(y in z) { print &quot;rcpt to:&quot; z[y]     |&amp; smtp;  smtp |&amp; getline j; print j }
  }
  else { print &quot;rcpt to:&quot; r                |&amp; smtp;  smtp |&amp; getline j; print j }
  print &quot;data&quot;                             |&amp; smtp;  smtp |&amp; getline j; print j

  print &quot;From:&quot; s                          |&amp; smtp;  ARGV[2] = &quot;&quot;   # not a file
  print &quot;To:&quot; r                            |&amp; smtp;  ARGV[1] = &quot;&quot;   # not a file
  if(length(sbj)) { print &quot;Subject: &quot; sbj  |&amp; smtp;  ARGV[3] = &quot;&quot; } # not a file
  print &quot;&quot;                                 |&amp; smtp

  while(getline &gt; 0) print                 |&amp; smtp

  print &quot;.&quot;                                |&amp; smtp;  smtp |&amp; getline j; print j
  print &quot;quit&quot;                             |&amp; smtp;  smtp |&amp; getline j; print j

  close(smtp) } # &#x2F;inet&#x2F;protocol&#x2F;local-port&#x2F;remote-host&#x2F;remote-port</code></pre>
"""#
        let expected = #"""
I like this one.

```
$ cat /usr/local/bin/awkmail
#!/bin/gawk -f
BEGIN { smtp="/inet/tcp/0/smtp.yourco.com/25";
ORS="\r\n"; r=ARGV[1]; s=ARGV[2]; sbj=ARGV[3]; # /bin/awkmail to from subj < in
print "helo " ENVIRON["HOSTNAME"]        |& smtp;  smtp |& getline j; print j
print "mail from:" s                     |& smtp;  smtp |& getline j; print j
if(match(r, ","))
{
 split(r, z, ",")
 for(y in z) { print "rcpt to:" z[y]     |& smtp;  smtp |& getline j; print j }
}
else { print "rcpt to:" r                |& smtp;  smtp |& getline j; print j }
print "data"                             |& smtp;  smtp |& getline j; print j
print "From:" s                          |& smtp;  ARGV[2] = ""   # not a file
print "To:" r                            |& smtp;  ARGV[1] = ""   # not a file
if(length(sbj)) { print "Subject: " sbj  |& smtp;  ARGV[3] = "" } # not a file
print ""                                 |& smtp
while(getline > 0) print                 |& smtp
print "."                                |& smtp;  smtp |& getline j; print j
print "quit"                             |& smtp;  smtp |& getline j; print j
close(smtp) } # /inet/protocol/local-port/remote-host/remote-port
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45677142() async throws {
        let html = #"""
<p>I have three different way to open file with vim:
v: vim (or neovim, in my case)
vv: search&#x2F;preview and open file by filename
vvv: search&#x2F;preview and open file by its content<p><pre><code>    alias v=&#x27;nvim&#x27;
    alias vv=&#x27;f=$(fzf --preview-window &quot;right:50%&quot; --preview &quot;bat --color=always {1}&quot;); test -n &quot;$f&quot; &amp;&amp; v &quot;$f&quot;&#x27;
    alias vvv=&#x27;f=$(rg --line-number --no-heading . | fzf -d: -n 2.. --preview-window &quot;right:50%:+{2}&quot; --preview &quot;bat --color=always --highlight-line {2} {1}&quot;); test -n &quot;$(echo &quot;$f&quot; | cut -d: -f1)&quot; &amp;&amp; v &quot;+$(echo &quot;$f&quot; | cut -d: -f2)&quot; &quot;$(echo &quot;$f&quot; | cut -d: -f1)&quot;&#x27;</code></pre>
"""#
        let expected = #"""
I have three different way to open file with vim:

v: vim (or neovim, in my case)

vv: search/preview and open file by filename

vvv: search/preview and open file by its content

```
alias v='nvim'
alias vv='f=$(fzf --preview-window "right:50%" --preview "bat --color=always {1}"); test -n "$f" && v "$f"'
alias vvv='f=$(rg --line-number --no-heading . | fzf -d: -n 2.. --preview-window "right:50%:+{2}" --preview "bat --color=always --highlight-line {2} {1}"); test -n "$(echo "$f" | cut -d: -f1)" && v "+$(echo "$f" | cut -d: -f2)" "$(echo "$f" | cut -d: -f1)"'
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45684759() async throws {
        let html = #"""
<p>I use my &quot;dc&quot; command to reverse &quot;cd&quot; frequently
<a href="https:&#x2F;&#x2F;gist.github.com&#x2F;GNOMES&#x2F;6bf65926648e260d8023aebb9ede9573" rel="nofollow">https:&#x2F;&#x2F;gist.github.com&#x2F;GNOMES&#x2F;6bf65926648e260d8023aebb9ede9...</a><p>Ex:<p><pre><code>    &gt; echo $PWD
    &#x2F;foo&#x2F;bar&#x2F;batz&#x2F;abc&#x2F;123

    &gt; dc bar &amp;&amp; echo $PWD
    &#x2F;foo&#x2F;bar
</code></pre>
Useful for times when I don&#x27;t want to type a long train of dot slashes(ex. cd ..&#x2F;..&#x2F;..).<p>Also useful when using Zoxide, and I tab complete into a directory tree path where parent directories are not in Zoxide history.<p>Added tab complete for speed.
"""#
        let expected = #"""
I use my "dc" command to reverse "cd" frequently
[https://gist.github.com/GNOMES/6bf65926648e260d8023aebb9ede9...](https://gist.github.com/GNOMES/6bf65926648e260d8023aebb9ede9573)

Ex:

```
> echo $PWD
/foo/bar/batz/abc/123
> dc bar && echo $PWD
/foo/bar
```
Useful for times when I don't want to type a long train of dot slashes(ex. cd ../../..).

Also useful when using Zoxide, and I tab complete into a directory tree path where parent directories are not in Zoxide history.

Added tab complete for speed.
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45682492() async throws {
        let html = #"""
<p>In fish, I have an abbreviation that automatically expands double dots into ..&#x2F; so that you can just spam double dots and visually see how far you&#x27;re going.<p><pre><code>  # Modified from
  # https:&#x2F;&#x2F;github.com&#x2F;fish-shell&#x2F;fish-shell&#x2F;issues&#x2F;1891#issuecomment-451961517
  function append-slash-to-double-dot -d &#x27;expand .. to ..&#x2F;&#x27;
   # Get commandline up to cursor
   set -l cmd (commandline --cut-at-cursor)
  
   # Match last line
   switch $cmd[-1]
   case &#x27;*.&#x27;
    commandline --insert &#x27;.&#x2F;&#x27;
   case &#x27;*&#x27;
    commandline --insert &#x27;.&#x27;
   end
  end</code></pre>
"""#
        let expected = #"""
In fish, I have an abbreviation that automatically expands double dots into ../ so that you can just spam double dots and visually see how far you're going.

```
# Modified from
# https://github.com/fish-shell/fish-shell/issues/1891#issuecomment-451961517
function append-slash-to-double-dot -d 'expand .. to ../'
 # Get commandline up to cursor
 set -l cmd (commandline --cut-at-cursor)
 # Match last line
 switch $cmd[-1]
 case '*.'
  commandline --insert './'
 case '*'
  commandline --insert '.'
 end
end
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45693487() async throws {
        let html = #"""
<p>I used to do this, but unary kind of sucks after 3; So maybe others might like this better before their fingers get trained:<p><pre><code>    ..() { # Usage: .. [N=1] -&gt; cd up N levels
      local d=&quot;&quot; i
      for ((i = 0; i &lt; ${1:-&quot;1&quot;}; i++))
        d=&quot;$d&#x2F;..&quot;  # Build up a string &amp; do 1 cd to preserve dirstack
      [[ -z $d ]] || cd .&#x2F;$d
    }
</code></pre>
Of course, what I <i>actually</i> have been doing since the early 90s is realize that a single &quot;.&quot; with no-args is normally illegal and people &quot;cd&quot; soooo much more often than sourcing script definitions.  So, I hijack that to save one &quot;.&quot; in the first 3 cases and then take a number for the general case.<p><pre><code>    # dash allows non-AlphaNumeric alias but not function names; POSIX is silent.
    cd1 () { if [ $# -eq 0 ]; then cd ..; else command . &quot;$@&quot;; fi; } # nice &quot;cd ..&quot;
    alias .=cd1
    cdu() {           # Usage: cdu [N=2] -&gt; cd up N levels
      local i=0 d=&quot;&quot;  # &quot;.&quot; already does 1 level
      while [ $i -lt ${1:-&quot;2&quot;} ]; do d=$d&#x2F;..; i=$((i+1)); done
      [ -z &quot;$d&quot; ] || cd .&#x2F;$d; }
    alias ..=cdu
    alias ...=&#x27;cd ..&#x2F;..&#x2F;..&#x27; # so, &quot;.&quot;=1up, &quot;..&quot;=2up, &quot;...&quot;=3up, &quot;.. N&quot;=Nup
</code></pre>
and as per the comment this even works in lowly dash, but needs a slight workaround.  bash can just do a .() and ..() shell function as with the zsh.
"""#
        let expected = #"""
I used to do this, but unary kind of sucks after 3; So maybe others might like this better before their fingers get trained:

```
..() { # Usage: .. [N=1] -> cd up N levels
  local d="" i
  for ((i = 0; i < ${1:-"1"}; i++))
    d="$d/.."  # Build up a string & do 1 cd to preserve dirstack
  [[ -z $d ]] || cd ./$d
}
```
Of course, what I *actually* have been doing since the early 90s is realize that a single "." with no-args is normally illegal and people "cd" soooo much more often than sourcing script definitions.  So, I hijack that to save one "." in the first 3 cases and then take a number for the general case.

```
# dash allows non-AlphaNumeric alias but not function names; POSIX is silent.
cd1 () { if [ $# -eq 0 ]; then cd ..; else command . "$@"; fi; } # nice "cd .."
alias .=cd1
cdu() {           # Usage: cdu [N=2] -> cd up N levels
  local i=0 d=""  # "." already does 1 level
  while [ $i -lt ${1:-"2"} ]; do d=$d/..; i=$((i+1)); done
  [ -z "$d" ] || cd ./$d; }
alias ..=cdu
alias ...='cd ../../..' # so, "."=1up, ".."=2up, "..."=3up, ".. N"=Nup
```
and as per the comment this even works in lowly dash, but needs a slight workaround.  bash can just do a .() and ..() shell function as with the zsh.
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45676254() async throws {
        let html = #"""
<p>fish lets you cd to a folder without &#x27;cd&#x27; although you still need the slashes. I use it all the time.<p><pre><code>    c $&gt; pwd
    &#x2F;a&#x2F;b&#x2F;c
    c $&gt; dir1
    dir1 $&gt; ..
    c $&gt; ..&#x2F;..
    &#x2F; $&gt;</code></pre>
"""#
        let expected = #"""
fish lets you cd to a folder without 'cd' although you still need the slashes. I use it all the time.

```
c $> pwd
/a/b/c
c $> dir1
dir1 $> ..
c $> ../..
/ $>
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45675304() async throws {
        let html = #"""
<p>Not on my Mac.<p><pre><code>    zsh: permission denied: ..
    zsh: command not found: ...</code></pre>
"""#
        let expected = #"""
Not on my Mac.

```
zsh: permission denied: ..
zsh: command not found: ...
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45674846() async throws {
        let html = #"""
<p>Nice! Tangentially related: I built a (MacOS only) tool called clippy to be a much better pbcopy. It was just added to homebrew core. Among other things, it auto-detects when you want files as references so they paste into GUI apps as uploads, not bytes.<p><pre><code>  clippy image.png  # then paste into Slack, etc. as upload

  clippy -r         # copy most recent download

  pasty             # copy file in Finder, then paste actual file here
</code></pre>
<a href="https:&#x2F;&#x2F;github.com&#x2F;neilberkman&#x2F;clippy" rel="nofollow">https:&#x2F;&#x2F;github.com&#x2F;neilberkman&#x2F;clippy</a> &#x2F; brew install clippy
"""#
        let expected = #"""
Nice! Tangentially related: I built a (MacOS only) tool called clippy to be a much better pbcopy. It was just added to homebrew core. Among other things, it auto-detects when you want files as references so they paste into GUI apps as uploads, not bytes.

```
clippy image.png  # then paste into Slack, etc. as upload
clippy -r         # copy most recent download
pasty             # copy file in Finder, then paste actual file here
```
[https://github.com/neilberkman/clippy](https://github.com/neilberkman/clippy) / brew install clippy
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45675125() async throws {
        let html = #"""
<p>Adding the word &quot;then&quot; to your first comment would have helped me: (lacking context, I thought the comments explained what the command does, as is common convention)<p><pre><code>  clippy image.png   # then paste into Slack, etc. as upload
</code></pre>
Also:<p><pre><code>  pasty              # paste actual file, after copying file in Finder</code></pre>
"""#
        let expected = #"""
Adding the word "then" to your first comment would have helped me: (lacking context, I thought the comments explained what the command does, as is common convention)

```
clippy image.png   # then paste into Slack, etc. as upload
```
Also:

```
pasty              # paste actual file, after copying file in Finder
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45674117() async throws {
        let html = #"""
<p>Share yours!<p>I use this as a bookmarklet to grab the front page of the new york times (print edition). (You can also go back to any date up to like 2011)<p>I think they go out at like 4 am. So, day-of, note that it will fail if you&#x27;re in that window before publishing.<p><pre><code>    javascript:(()=&gt;{let d=new Date(new Date().toLocaleString(&#x27;en-US&#x27;,{timeZone:&#x27;America&#x2F;New_York&#x27;})),y=d.getFullYear(),m=(&#x27;0&#x27;+(d.getMonth()+1)).slice(-2),g=(&#x27;0&#x27;+d.getDate()).slice(-2);location.href=`https:&#x2F;&#x2F;static01.nyt.com&#x2F;images&#x2F;${y}&#x2F;${m}&#x2F;${g}&#x2F;nytfrontpage&#x2F;scan.pdf`})()</code></pre>
"""#
        let expected = #"""
Share yours!

I use this as a bookmarklet to grab the front page of the new york times (print edition). (You can also go back to any date up to like 2011)

I think they go out at like 4 am. So, day-of, note that it will fail if you're in that window before publishing.

```
javascript:(()=>{let d=new Date(new Date().toLocaleString('en-US',{timeZone:'America/New_York'})),y=d.getFullYear(),m=('0'+(d.getMonth()+1)).slice(-2),g=('0'+d.getDate()).slice(-2);location.href=`https://static01.nyt.com/images/${y}/${m}/${g}/nytfrontpage/scan.pdf`})()
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45681752() async throws {
        let html = #"""
<p>As a programmer, you sometimes want to make an alphabet lookup table. So, something like:<p><pre><code>  var alpha_lu = &quot;abcdefghijklmnopqrstuvwxyz&quot;;
</code></pre>
Typing it out by hand is error prone as it&#x27;s not easy to see if you&#x27;ve swapped the order or missed a character.<p>I&#x27;ve needed the alphabet string or lookup rarely, but I have needed it before. Some applications could include making your own UUID function, making a small random naming scheme, associating small categorical numbers to letters, etc.<p>The author of article mentioned they do web development, so it&#x27;s not hard to imagine they&#x27;ve had to create a URL shortener, maybe more than once. So, for example, creating a small name could look like:<p><pre><code>  function small_name(len) {
    let a = &quot;abcdefghijklmnopqrstuvwxyz&quot;,
        v = [];
    for (let i=0; i&lt;len; i++) {
      v.push( a[ Math.floor( Math.random()*a.length ) ] );
    }
    return v.join(&quot;&quot;);
  }
  &#x2F;&#x2F;...
  small_name(5); &#x2F;&#x2F; e.g. &quot;pfsor&quot;
</code></pre>
Dealing with strings, dealing with hashes, random names, etc., one could imagine needing to do functions like this, or functions that are adjacent to these types of tasks, at least once a month.<p>Just a guess on my part though.
"""#
        let expected = #"""
As a programmer, you sometimes want to make an alphabet lookup table. So, something like:

```
var alpha_lu = "abcdefghijklmnopqrstuvwxyz";
```
Typing it out by hand is error prone as it's not easy to see if you've swapped the order or missed a character.

I've needed the alphabet string or lookup rarely, but I have needed it before. Some applications could include making your own UUID function, making a small random naming scheme, associating small categorical numbers to letters, etc.

The author of article mentioned they do web development, so it's not hard to imagine they've had to create a URL shortener, maybe more than once. So, for example, creating a small name could look like:

```
function small_name(len) {
  let a = "abcdefghijklmnopqrstuvwxyz",
      v = [];
  for (let i=0; i<len; i++) {
    v.push( a[ Math.floor( Math.random()*a.length ) ] );
  }
  return v.join("");
}
//...
small_name(5); // e.g. "pfsor"
```
Dealing with strings, dealing with hashes, random names, etc., one could imagine needing to do functions like this, or functions that are adjacent to these types of tasks, at least once a month.

Just a guess on my part though.
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45677976() async throws {
        let html = #"""
<p>Are you referring to the nato alphabet utility? Or the alphabet script that prints<p><pre><code>  abcdefghijklmnopqrstuvwxyz
  ABCDEFGHIJKLMNOPQRSTUVWXYZ</code></pre>
"""#
        let expected = #"""
Are you referring to the nato alphabet utility? Or the alphabet script that prints

```
abcdefghijklmnopqrstuvwxyz
ABCDEFGHIJKLMNOPQRSTUVWXYZ
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45675603() async throws {
        let html = #"""
<p><pre><code>    alias mpa=&#x27;mpv --no-video&#x27;

    mpa [youtube_url]
</code></pre>
I use this to listen to music &#x2F; lectures in the terminal.<p>I think it needs yt-dlp installed — and reasonably up to date, since YouTube keeps breaking yt-dlp... but the updates keep fixing it :)
"""#
        let expected = #"""
```
alias mpa='mpv --no-video'
mpa [youtube_url]
```
I use this to listen to music / lectures in the terminal.

I think it needs yt-dlp installed — and reasonably up to date, since YouTube keeps breaking yt-dlp... but the updates keep fixing it :)
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45675633() async throws {
        let html = #"""
<p>On the subject of yt-dlp, I use it to get (timestamped) transcripts from YouTube, to shove into LLMs for summaries.<p><pre><code>    ytsub() {
        yt-dlp \
            --write-sub \
            --write-auto-sub \
            --sub-lang &quot;en.*&quot; \
            --skip-download \
            &quot;$1&quot; &amp;&amp; vtt2txt
    }

    ytsub [youtube_url]
</code></pre>
Where vtt2txt is a python script — slightly too long to paste here — which strips out the subtitle formatting, leaving a (mostly) human readable transcript.
"""#
        let expected = #"""
On the subject of yt-dlp, I use it to get (timestamped) transcripts from YouTube, to shove into LLMs for summaries.

```
ytsub() {
    yt-dlp \
        --write-sub \
        --write-auto-sub \
        --sub-lang "en.*" \
        --skip-download \
        "$1" && vtt2txt
}
ytsub [youtube_url]
```
Where vtt2txt is a python script — slightly too long to paste here — which strips out the subtitle formatting, leaving a (mostly) human readable transcript.
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45679929() async throws {
        let html = #"""
<p>on my ubuntu, `date -I` does iso dates<p>Also re: alphabet<p><pre><code>    $ echo {a..z}
    a b c d e f g h i j k l m n o p q r s t u v w x y z</code></pre>
"""#
        let expected = #"""
on my ubuntu, `date -I` does iso dates

Also re: alphabet

```
$ echo {a..z}
a b c d e f g h i j k l m n o p q r s t u v w x y z
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45680059() async throws {
        let html = #"""
<p>date -I even works on macOS, which I was pleasantly surprised by!<p>If you want the exact alphabet behaviour as the OP:<p><pre><code>    $ echo {a..z} $&#x27;\n&#x27; {A..Z} | tr -d &#x27; &#x27;</code></pre>
"""#
        let expected = #"""
date -I even works on macOS, which I was pleasantly surprised by!

If you want the exact alphabet behaviour as the OP:

```
$ echo {a..z} $'\n' {A..Z} | tr -d ' '
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45678794() async throws {
        let html = #"""
<p>The most useful script I wrote is one I call `posh`. It shorten a file path by using environment variables. Example:<p><pre><code>  $ posh &#x2F;home&#x2F;ramrachum&#x2F;Dropbox&#x2F;notes.txt
  $DX&#x2F;notes.txt
</code></pre>
Of course, it only becomes useful when you define a bunch of environment variables for the paths that you use often.<p>I use this a lot in all of my scripts. Basically whenever any of my script prints a path, it passes it through `posh`.
"""#
        let expected = #"""
The most useful script I wrote is one I call `posh`. It shorten a file path by using environment variables. Example:

```
$ posh /home/ramrachum/Dropbox/notes.txt
$DX/notes.txt
```
Of course, it only becomes useful when you define a bunch of environment variables for the paths that you use often.

I use this a lot in all of my scripts. Basically whenever any of my script prints a path, it passes it through `posh`.
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45684923() async throws {
        let html = #"""
<p>One I use a lot is kp, it kills a process listening to a particular TCP port.<p><pre><code>  kp () {
           if [ -z &quot;$1&quot; ] then
                   echo &quot;Usage: kp &lt;port&gt;&quot;
                   return 1
           fi
           lsof -nP -iTCP:&quot;$1&quot; -sTCP:LISTEN | awk &#x27;NR&gt;1 {print $2}&#x27; | xargs kill -9
   }</code></pre>
"""#
        let expected = #"""
One I use a lot is kp, it kills a process listening to a particular TCP port.

```
kp () {
         if [ -z "$1" ] then
                 echo "Usage: kp <port>"
                 return 1
         fi
         lsof -nP -iTCP:"$1" -sTCP:LISTEN | awk 'NR>1 {print $2}' | xargs kill -9
 }
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45678555() async throws {
        let html = #"""
<p>Please note that &#x27;each&#x27; is fundamentally different from &#x27;xargs&#x27;.<p><pre><code>  echo 1 2 3 | each &quot;rm {}&quot;
</code></pre>
is the same as<p><pre><code>  rm 1
  rm 2
  rm 3
</code></pre>
while<p><pre><code>  echo 1 2 3 | xargs rm
</code></pre>
is the same as<p><pre><code>  rm 1 2 3
</code></pre>
I would rather say that &#x27;each&#x27; replaces (certain uses of) &#x27;for&#x27;:<p><pre><code>  for i in 1 2 3; do rm $i; done</code></pre>
"""#
        let expected = #"""
Please note that 'each' is fundamentally different from 'xargs'.

```
echo 1 2 3 | each "rm {}"
```
is the same as

```
rm 1
rm 2
rm 3
```
while

```
echo 1 2 3 | xargs rm
```
is the same as

```
rm 1 2 3
```
I would rather say that 'each' replaces (certain uses of) 'for':

```
for i in 1 2 3; do rm $i; done
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45678621() async throws {
        let html = #"""
<p>It&#x27;s equivalent to xargs -I {} rm {}<p><pre><code>       -I replace-str
              Replace occurrences of replace-str in the initial-arguments
              with names read from standard input.  Also, unquoted blanks
              do not terminate input items; instead the separator is the
              newline character.  Implies -x and -L 1.</code></pre>
"""#
        let expected = #"""
It's equivalent to xargs -I {} rm {}

```
-I replace-str
       Replace occurrences of replace-str in the initial-arguments
       with names read from standard input.  Also, unquoted blanks
       do not terminate input items; instead the separator is the
       newline character.  Implies -x and -L 1.
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45674131() async throws {
        let html = #"""
<p>An important advantage of aliases was not mentioned: I see everything in one place and can easily build aliases on top of other aliases without much thinking.<p>Anyways, my favourite alias that I use all the time is this:<p><pre><code>    alias a=&#x27;nvim ~&#x2F;.zshrc &amp;&amp; . ~&#x2F;.zshrc&#x27;
</code></pre>
It solves the ,,not loaded automatically&#x27;&#x27; part at least for the current terminal
"""#
        let expected = #"""
An important advantage of aliases was not mentioned: I see everything in one place and can easily build aliases on top of other aliases without much thinking.

Anyways, my favourite alias that I use all the time is this:

```
alias a='nvim ~/.zshrc && . ~/.zshrc'
```
It solves the ,,not loaded automatically'' part at least for the current terminal
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45680014() async throws {
        let html = #"""
<p>My most used function is probably the one I use to find the most recent files:<p><pre><code>    lt () { ls --color=always -lt ${1} | head }</code></pre>
"""#
        let expected = #"""
My most used function is probably the one I use to find the most recent files:

```
lt () { ls --color=always -lt ${1} | head }
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }

    @Test func comment45676488() async throws {
        let html = #"""
<p>or even better:<p><pre><code>  :&#x27;&lt;,&#x27;&gt;s&#x2F;^&#x2F;&gt; &#x2F;</code></pre>
"""#
        let expected = #"""
or even better:

```
:'<,'>s/^/> /
```
"""#
        let output = await markdown.convert(html)
        #expect(output == expected)
    }
}