#!/usr/bin/env ruby
#
# Copyright (C) 2016-2017 Harald Sitter <sitter@kde.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License or (at your option) version 3 or any later version
# accepted by the membership of KDE e.V. (or its successor approved
# by the membership of KDE e.V.), which shall act as a proxy
# defined in Section 14 of version 3 of the license.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

(1..4).each do |i|
  host = format('do-builder-%03d', i)
  puts "---- #{host} -----"
  # Make sure old kernels get ripped out (first thing as to speed up grub's
  # postinst) also we'll want to keep the running kernel in case a rollback is
  # needed.
  system('ssh', "root@#{host}", 'apt-get', 'autoremove', '--purge', '-y')
  system('ssh', "root@#{host}", 'apt', 'update')
  system('ssh', "root@#{host}", 'apt', 'dist-upgrade', '-y')
  # Sleep a bit to let the system settle down before we murder it.
  sleep(8)
  system('ssh', "root@#{host}", 'reboot')
end
