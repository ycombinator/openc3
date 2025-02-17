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
  <!-- Dialog for creating new screen -->
  <v-dialog v-model="show" width="600">
    <v-card>
      <v-system-bar>
        <v-spacer />
        <span>Create New Screen</span>
        <v-spacer />
        <v-tooltip top>
          <template v-slot:activator="{ on, attrs }">
            <div v-on="on" v-bind="attrs">
              <v-icon data-test="new-screen-close-icon" @click="show = false">
                mdi-close-box
              </v-icon>
            </div>
          </template>
          <span>Close</span>
        </v-tooltip>
      </v-system-bar>
      <!-- <v-card-title> Create New Screen </v-card-title> -->
      <v-card-text>
        <div class="pa-3">
          <v-alert
            v-model="duplicateScreenAlert"
            type="error"
            dismissible
            dense
          >
            Screen {{ newScreenName.toUpperCase() }} already exists!
          </v-alert>

          <v-row class="pb-2">
            <span>Existing Screens: {{ screens.join(', ') }}</span>
          </v-row>
          <v-row>
            <v-text-field
              v-model="newScreenName"
              flat
              autofocus
              solo-inverted
              hide-details
              clearable
              label="Screen Name (without .txt)"
              data-test="new-screen-name"
              @keyup="newScreenKeyup($event)"
            />
            <div class="pl-2" v-if="newScreenSaving">
              <v-progress-circular indeterminate color="primary" />
            </div>
          </v-row>
        </div>
      </v-card-text>
      <v-divider />
      <v-card-actions>
        <v-btn color="primary" text @click="saveNewScreen"> Ok </v-btn>
        <v-btn text @click="show = false"> Cancel </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
export default {
  props: {
    value: Boolean, // value is the default prop when using v-model
    screens: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      newScreenSaving: false,
      newScreenName: '',
      duplicateScreenAlert: false,
    }
  },
  created() {
    this.duplicateScreenAlert = false
    this.newScreenSaving = false
  },
  computed: {
    show: {
      get() {
        return this.value
      },
      set(value) {
        this.$emit('input', value) // input is the default event when using v-model
      },
    },
  },
  methods: {
    newScreenKeyup(event) {
      if (this.screens.indexOf(this.newScreenName.toUpperCase()) !== -1) {
        this.duplicateScreenAlert = true
      } else {
        this.duplicateScreenAlert = false
        if (event.key === 'Enter') {
          this.saveNewScreen()
        }
      }
    },
    saveNewScreen() {
      this.newScreenSaving = true
      this.$emit('success', this.newScreenName.toUpperCase())
    },
  },
}
</script>
