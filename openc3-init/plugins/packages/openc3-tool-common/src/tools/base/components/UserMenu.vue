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
    <v-overlay :value="showUserMenu" class="overlay" />
    <v-menu
      v-model="showUserMenu"
      transition="slide-y-transition"
      offset-y
      :close-on-content-click="false"
      :nudge-width="120"
      :nudge-bottom="20"
    >
      <template v-slot:activator="{ on, attrs }">
        <v-btn v-bind="attrs" v-on="on" icon>
          <v-icon :size="size"> mdi-account </v-icon>
        </v-btn>
      </template>

      <v-card>
        <v-card-text class="text-center">
          <div style="text-align: center; margin: 5px">{{ username }}</div>
          <div v-if="authenticated">
            <v-btn block @click="logout" color="primary"> Logout </v-btn>
          </div>
          <div v-else>
            <v-btn block @click="login" color="primary"> Login </v-btn>
          </div>
          <div>
            <v-switch label="Colorblind mode" v-model="colorblindMode" />
          </div>
        </v-card-text>
      </v-card>
    </v-menu>
  </div>
</template>

<script>
export default {
  props: {
    size: {
      type: [String, Number],
      default: 26,
    },
  },
  data: function () {
    let user = OpenC3Auth.user()
    return {
      showUserMenu: false,
      authenticated: !!localStorage.openc3Token,
      username: user['name'],
    }
  },
  computed: {
    colorblindMode: {
      get: function () {
        return localStorage.colorblindMode === 'true'
      },
      set: function (val) {
        localStorage.colorblindMode = val
      },
    },
  },
  methods: {
    logout: function () {
      OpenC3Auth.logout()
    },
    login: function () {
      OpenC3Auth.login(location.href)
    },
  },
}
</script>

<style scoped>
.overlay {
  height: 100vh;
  width: 100vw;
}
</style>
