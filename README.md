oDisk
=====

Remote Encrypted File Synchronization, oDisk

oDisk is a file synchronization application. The need for oDisk came from the
discontinuation of Apple's iDisk. oDisk provides a means to backup to a remote
host. oDisk encrypts and compresses backups to save space and provide a layer
of security not found in iDisk or other backup schemes. Backups are stored as
individual files to provide finer granularity in recover if everything else
falls apart.

oDisk is also a demonstration of the [Opee](http://www.ohler.com/opee) gem
which utilizes an alternative approach to dealing with multiple threads.

## <a name="source">Source</a>

*GitHub* *repo*: https://github.com/ohler55/odisk

*RubyGems* *repo*: https://rubygems.org/gems/odisk

## <a name="links">Links of Interest</a>

[Object-based Parallel Evaluation Environment](http://www.ohler.com/opee) the gem oDisk is built on.

## <a name="release">Release Notes</a>

### Release 1.0.2

 - Made groups handling more tolerant.

 - Updated gpg command arguments for more modern version.

### Release 1.0.1

 - Ruby time has changed so a change in time comparisons was made.

### Release 1.0.0

 - Added support for the Opee/OTerm Inspector

 - Fixed race condition on shutdown bug

### Release 0.9.0

 - Updated to work properly with Ubuntu 12. 

 - Note: the version has been bumped up to 0.9 indicating it is stable enough to use. I have been using it for several months without a problem on 3 Macs and now one Ubuntu machine.

# Plans and Notes

So far the basic backup functionality works with backups encrypted and compressed on a remote server. Adding new files
and making modifications works just fine. Removing files has not been fully implemented yet and changing ownership or
mode only take effect if the file is touched as well. Feel free to give it a try and let me know when you run into bugs.

 - Support ignore of file and directories
  - specify on command line and create .odisk/ignore file
   - use ::File.fnmatch(pattern, path, ::File::FNM_DOTMATCH)
  - pass array of ignores to digest creation
   - loosen up current restriction on any file that begins with .

 - Handle changes in mode, owner, and group
  - Compare to previous digest to detect changes
   - File modification times are not changed by mode, owner, or group changes
  - Note conflicts if modifications are more recent than remote
   - Use a script to pick change or keep local version

 - Add progress tracker
  - Have component pass info to progress actor which will update progress
   - Planner sends info on all changes along with sizes and comp/crypt flags to progress actor
    - come up with algoritm for estimating time based on size and flags
   - comp, crypt, and transfer send status to progress actor
  - Optional terminal display

 - Support background application with web front end (much later)

## Installation

Installation requires Ruby 1.9.3. After that, install the odisk gem.

    gem install odisk

The net-ssh and net-sftp gems are also needed as are the oj and opee gems.

    gem install net-ssh
    gem install net-sftp
    gem install oj
    gem install opee

GnuPG must be installed. It can be down loaded from
[GnuPG.org](http://www.gnupg.org). Follow the instruction on
[GnuPG.org](http://www.gnupg.org) site for installation.

oDisk is now ready to use. ssh and sftp must be running on the remote site and
credentials must be installed so that the user is not prompted for a password
when using ssh or sftp.

## Usage

After a directory has been selected for backing up *odisk* can be run to
copy the directory to a remote server. For purposes of this description the
directory to be backed up is *~/backup*.

A passphrase file will also be needed for encryption. The recommended location
is in a *~/.odisk* directory. The contents of the file will be the passphrase
for *gpg*.

Make sure you have a remote server that has an sftp and ssh daemon
running. Your credentials must be set in the authorized_keys file. If you can
login without a password it is set up correctly.

The first time *odisk* is used to backup a directory information about the
remote server must be provided. After the first time that information is not
needed again. Alternatively a *~/.odisk/remotes* file can be set up before
running *odisk*.

To backup to *my_server.remote.com* for user *me* to the *backup* directory on
the remote server with a passphrase file of *~/.odisk/backup.pass* the
following command should be executed.

    odisk -r me@my_server.remote.com:~/.odisk/backup.pass ~/backup

A file named *~/backup/.odisk/remote* will be created with the connection
information for future invocations so that the next time a backup is made on
the *~/backup* directory the command only needs to be:

    odisk ~/backup

## License:

    Copyright (c) 2012, Peter Ohler
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
     - Redistributions of source code must retain the above copyright notice, this
       list of conditions and the following disclaimer.
    
     - Redistributions in binary form must reproduce the above copyright notice,
       this list of conditions and the following disclaimer in the documentation
       and/or other materials provided with the distribution.
    
     - Neither the name of Peter Ohler nor the names of its contributors may be
       used to endorse or promote products derived from this software without
       specific prior written permission.
    
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
