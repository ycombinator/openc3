<!--
# Copyright 2022 OpenC3, Inc.
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
-->

<template>
  <graph
    :ref="'graph' + id"
    :id="id"
    :state="state"
    :selected-graph-id="id"
    :seconds-graphed="secondsGraphed"
    :points-saved="pointsSaved"
    :points-graphed="pointsGraphed"
    :initial-items="items"
    :height="size.height"
    :width="size.width"
    sparkline
  />
</template>

<script>
import Widget from './Widget'
import Graph from '../Graph.vue'

const valueType = 'CONVERTED'
export default {
  components: {
    Graph,
  },
  mixins: [Widget],
  data: function () {
    return {
      id: Math.floor(Math.random() * 100000000000), // Unique-ish
      state: 'start',
      items: [
        {
          targetName: this.parameters[0],
          packetName: this.parameters[1],
          itemName: this.parameters[2],
          valueType,
        },
      ],
      secondsGraphed: 300,
      pointsSaved: 300,
      pointsGraphed: 300,
      size: {
        height: 30,
        width: 130,
      },
    }
  },
  created: function () {
    this.settings.forEach((setting) => {
      switch (setting[0]) {
        case 'ITEM':
          this.items.push({
            targetName: setting[1],
            packetName: setting[2],
            itemName: setting[3],
            valueType,
          })
        case 'SECONDSGRAPHED':
          this.secondsGraphed = parseInt(setting[1])
          break
        case 'POINTSSAVED':
          this.pointsSaved = parseInt(setting[1])
          break
        case 'POINTSGRAPHED':
          this.pointsGraphed = parseInt(setting[1])
          break
        case 'SIZE':
          this.size.width = parseInt(setting[1])
          this.size.height = parseInt(setting[2])
          break
      }
    })
  },
}
</script>
