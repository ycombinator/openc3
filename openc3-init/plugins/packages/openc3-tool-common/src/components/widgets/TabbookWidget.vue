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
  <div>
    <v-tabs v-model="curTab">
      <v-tab v-for="(tab, index) in widgets" :key="index">
        {{ tab.parameters[0] }}
      </v-tab>
    </v-tabs>
    <v-tabs-items v-model="curTab">
      <v-tab-item v-for="(tab, tabIndex) in widgets" :key="tabIndex">
        <component
          v-for="(widget, widgetIndex) in tab.widgets"
          v-on="$listeners"
          :key="`${tabIndex}-${widgetIndex}`"
          :is="widget.type"
          :target="widget.target"
          :parameters="widget.parameters"
          :settings="widget.settings"
          :widgets="widget.widgets"
          :name="widget.name"
          :line="widget.line"
          :lineNumber="widget.lineNumber"
        />
      </v-tab-item>
    </v-tabs-items>
  </div>
</template>

<script>
import Layout from './Layout'
export default {
  mixins: [Layout],
  data: function () {
    return {
      curTab: null,
    }
  },
  watch: {
    curTab: function () {
      this.$emit('min-max-screen')
    },
  },
}
</script>
