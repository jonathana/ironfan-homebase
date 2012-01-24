#
# Cookbook Name::       volumes
# Description::         Resize mountables in node[:volumes] to fill the volume
# Recipe::              resize
# Author::              Philip (flip) Kromer - Infochimps, Inc
#
# Copyright 2011, Philip (flip) Kromer - Infochimps, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

volumes(node).each do |vol_name, vol|
  next unless vol.resizable?

  if not vol.attached?
    Chef::Log.info "Before mounting, you must attach the #{vol_name} volume at #{vol.device}"
    next
  end

  case vol.fstype
  when 'ext2', 'ext3', 'ext4'
    bash "fsck #{vol_name} before resizing" do
      code      "fsck -f #{vol.device}"
    end
    r = bash "resize #{vol_name}" do
      code      "resize2fs #{vol.device}"
      action :nothing
    end
  when 'xfs'
    if not vol.mounted? then Chef::Log.info("Skipping resize of #{vol.fstype} volume #{vol_name}: not mounted (#{vol.inspect})") ; next ; end
    r = bash "resize #{vol_name}" do
      code      "xfs_growfs #{vol.device}"
      action :nothing
    end
  else return
  end
  r.run_action(:run)

  # don't resize again
  vol.resized!
end
