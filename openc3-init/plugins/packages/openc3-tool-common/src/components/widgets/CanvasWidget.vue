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
  <svg id="canvas" :width="width" :height="height">
    <component
      v-for="(widget, index) in widgets"
      v-on="$listeners"
      :key="index"
      :is="widget.type"
      :target="widget.target"
      :parameters="widget.parameters"
      :settings="widget.settings"
      :widgets="widget.widgets"
      :name="widget.name"
      :line="widget.line"
      :lineNumber="widget.lineNumber"
    />
  </svg>
</template>

<script>
import Layout from './Layout'
export default {
  mixins: [Layout],
  computed: {
    width() {
      return this.parameters[0] + 'px'
    },
    height() {
      return this.parameters[1] + 'px'
    },
  },
}
</script>

<style lang="scss" scoped>
svg {
  background-color: white;
}
</style>
