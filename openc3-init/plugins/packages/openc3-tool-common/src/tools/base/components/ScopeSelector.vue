<!--
# Copyright 2022 Ball Aerospace & Technologies Corp.
# All Rights Reserved.
#
# This program is free software; you can modify and/or redistribute it
# under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; version 3 with
# attribution addendums as found in the LICENSE.txt
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# Modified by OpenC3, Inc.
# All changes Copyright 2022, OpenC3, Inc.
# All Rights Reserved
-->

<template>
  <v-select
    v-model="scope"
    :items="scopes"
    :disabled="scopes.length <= 1"
    label="Scope"
    dense
    hide-details
  />
</template>

<script>
export default {
  data: function () {
    return {
      scopes: ['DEFAULT'],
      scope: 'DEFAULT',
    }
  },
}
</script>
