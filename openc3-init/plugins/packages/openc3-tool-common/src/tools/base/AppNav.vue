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
    <v-navigation-drawer v-model="drawer" app id="openc3-nav-drawer">
      <v-list>
        <v-list-item>
          <v-list-item-icon
            style="
              margin-right: auto !important;
              margin-left: auto;
              margin-top: 0px;
              margin-bottom: 0px;
            "
          >
            <img :src="logo" alt="OpenC3" />
          </v-list-item-icon>
        </v-list-item>
        <div style="text-align: center; font-size: 18pt">{{ edition }}</div>
        <v-list-item class="my-0">
          <v-list-item-content>
            <div v-for="(tool, name) in adminTools" :key="name">
              <v-btn
                block
                small
                :href="tool.url"
                onclick="singleSpaNavigate(event)"
              >
                Admin
              </v-btn>
            </div>
          </v-list-item-content>
        </v-list-item>
        <v-divider />
        <div v-for="(tool, name) in shownTools" :key="name">
          <v-list-item class="pr-0">
            <v-list-item-icon>
              <a :href="tool.url" onclick="singleSpaNavigate(event)">
                <v-icon>{{ tool.icon }}</v-icon>
              </a>
            </v-list-item-icon>
            <v-list-item-content>
              <a :href="tool.url" onclick="singleSpaNavigate(event)">
                <v-list-item-title>{{ name }}</v-list-item-title>
              </a>
            </v-list-item-content>
            <v-divider vertical />
            <v-list-item-icon>
              <a :href="newTabUrl(tool)" target="_blank">
                <v-icon>mdi-open-in-new</v-icon>
              </a>
            </v-list-item-icon>
          </v-list-item>
        </div>
      </v-list>
    </v-navigation-drawer>
    <v-app-bar app color="tertiary darken-3" id="openc3-app-toolbar">
      <v-app-bar-nav-icon @click="drawer = !drawer" />
      <v-divider vertical class="top-bar-divider-full-height" />
      <span style="width: 100%"><span id="openc3-menu"></span></span>
      <div class="justify-right mr-2 pt-2"><scope-selector /></div>
      <div class="justify-right" data-test="alert-history">
        <alert-history />
      </div>
      <div class="justify-right" data-test="notifications">
        <notifications />
      </div>
      <div class="justify-right" data-test="user-menu"><user-menu /></div>
    </v-app-bar>
  </div>
</template>

<script>
import Api from '../../services/api'
import logo from '../../../public/img/logo.png'
import { registerApplication, start } from 'single-spa'
import ScopeSelector from './components/ScopeSelector.vue'
import AlertHistory from './components/AlertHistory.vue'
import Notifications from './components/Notifications.vue'
import UserMenu from './components/UserMenu.vue'

export default {
  components: {
    ScopeSelector,
    AlertHistory,
    Notifications,
    UserMenu,
  },
  props: {
    edition: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      drawer: true,
      appNav: {},
      adminNav: {},
      checked: [],
      logo: logo,
    }
  },
  computed: {
    // a computed getter
    shownTools: function () {
      let result = {}
      for (var key of Object.keys(this.appNav)) {
        if (this.appNav[key].shown && this.appNav[key].category !== 'Admin') {
          result[key] = this.appNav[key]
        }
      }
      return result
    },
    adminTools: function () {
      let result = {}
      for (var key of Object.keys(this.appNav)) {
        if (this.appNav[key].shown && this.appNav[key].category === 'Admin') {
          result[key] = this.appNav[key]
        }
      }
      return result
    },
  },
  created() {
    Api.get('/openc3-api/tools/all', { params: { scope: 'DEFAULT' } }).then(
      (response) => {
        this.appNav = response.data

        // Register apps and start single-spa
        for (var key of Object.keys(this.appNav)) {
          if (this.appNav[key].shown) {
            let folder_name = this.appNav[key].folder_name
            let name = '@openc3/tool-' + folder_name
            registerApplication({
              name: name,
              app: () => System.import(name),
              activeWhen: ['/tools/' + folder_name],
            })
          }
        }
        start({
          urlRerouteOnly: true,
        })

        // Redirect / to the first tool
        if (window.location.pathname == '/') {
          for (var key of Object.keys(this.shownTools)) {
            if (this.appNav[key].shown) {
              history.replaceState(null, '', this.appNav[key].url)
              break
            }
          }
        }

        // Check every minute if we need to update our token
        setInterval(() => {
          OpenC3Auth.updateToken(120)
        }, 60000)
      }
    )
  },
  methods: {
    newTabUrl(tool) {
      let url = null
      if (tool.url[0] == '/' && tool.url[1] != '/') {
        url = new URL(tool.url, window.location.origin)
      } else {
        url = new URL(tool.url)
      }
      url.searchParams.set('scope', window.openc3Scope)
      return url.href
    },
  },
}
</script>

<style scoped>
.v-list-item--two-line .v-list-item__icon {
  margin: 0px;
}
.v-list :deep(.v-label) {
  margin-left: 5px;
}
.theme--dark.v-navigation-drawer {
  background-color: var(--v-primary-darken2);
}
.v-list-item__icon {
  /* For some reason the default margin-right is huge */
  margin-right: 15px !important;
}
.v-list-item__title {
  color: white;
}

#openc3-app-toolbar .top-bar-divider-full-height {
  margin: -4px 4px;
  min-height: calc(100% + 8px);
}
</style>
