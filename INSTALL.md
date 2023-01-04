# INSTALLATION INSTRUCTIONS #

The latest version of this software is always available from Github

```
git clone https://github.com/aspeer/pl-slstidy.git
cd pl-slstidy
```

If on a modern system:

`cpan .`

Or (faster, if available):

`cpanm .`

Failing that manual install: 

```
perl Makefile.PL
make
make test
make install
```

If installing manually dependecies will have to be installed individually.
