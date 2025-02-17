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
  <v-dialog persistent v-model="show" width="600">
    <v-card>
      <v-card-text>
        <v-row class="mt-3">
          <v-col cols="12">
            <h3>{{ pluginName }}</h3>
          </v-col>
          <v-radio-group
            v-if="existingPluginTxt !== null"
            v-model="radioGroup"
            mandatory
          >
            <v-radio label="Use existing plugin.txt" :value="1"></v-radio>
            <v-radio label="Use new plugin.txt" :value="0"></v-radio>
          </v-radio-group>
        </v-row>
        <v-tabs v-model="tab" background-color="primary" dark>
          <v-tab :key="0"> Variables </v-tab>
          <v-tab :key="1"> plugin.txt </v-tab>
          <v-tab v-if="existingPluginTxt !== null" :key="2">
            Existing plugin.txt
          </v-tab>
        </v-tabs>

        <form v-on:submit.prevent="submit">
          <v-tabs-items v-model="tab">
            <v-tab-item :key="0">
              <v-card-text>
                <div class="pa-3">
                  <v-row class="mt-3">
                    <div v-for="(value, name) in localVariables" :key="name">
                      <v-col>
                        <v-text-field
                          clearable
                          type="text"
                          :label="name"
                          v-model="localVariables[name]"
                        />
                      </v-col>
                    </div>
                  </v-row>
                </div>
              </v-card-text>
            </v-tab-item>
            <v-tab-item :key="1">
              <v-textarea
                v-model="localPluginTxt"
                rows="15"
                data-test="edit-plugin-txt"
              />
            </v-tab-item>
            <v-tab-item v-if="existingPluginTxt !== null" :key="2">
              <v-textarea
                v-model="localExistingPluginTxt"
                rows="15"
                data-test="edit-existing-plugin-txt"
              />
            </v-tab-item>
          </v-tabs-items>

          <v-row>
            <v-spacer />
            <v-btn
              @click.prevent="close"
              outlined
              class="mx-2"
              data-test="edit-cancel"
            >
              Cancel
            </v-btn>
            <v-btn
              class="mx-2"
              color="primary"
              type="submit"
              data-test="edit-submit"
            >
              Install
            </v-btn>
          </v-row>
        </form>
      </v-card-text>
    </v-card>
  </v-dialog>
</template>

<script>
export default {
  props: {
    pluginName: {
      type: String,
      required: true,
    },
    variables: {
      type: Object,
      required: true,
    },
    pluginTxt: {
      type: String,
      required: true,
    },
    existingPluginTxt: {
      type: String,
      required: false,
    },
    value: Boolean, // value is the default prop when using v-model
  },
  data() {
    return {
      tab: 0,
      localVariables: [],
      localPluginTxt: '',
      localExistingPluginTxt: null,
      radioGroup: 1,
    }
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
  watch: {
    value: {
      immediate: true,
      handler: function () {
        this.localVariables = JSON.parse(JSON.stringify(this.variables)) // deep copy
        this.localPluginTxt = this.pluginTxt.slice()
        if (this.existingPluginTxt !== null) {
          this.localExistingPluginTxt = this.existingPluginTxt.slice()
          this.radioGroup = 1
        }
      },
    },
  },
  methods: {
    submit: function () {
      let lines = ''
      if (this.existingPluginTxt !== null && this.radioGroup === 1) {
        lines = this.localExistingPluginTxt.split('\n')
      } else {
        lines = this.localPluginTxt.split('\n')
      }

      let pluginHash = {
        name: this.pluginName,
        variables: this.localVariables,
        plugin_txt_lines: lines,
      }
      this.$emit('submit', pluginHash)
    },
    close: function () {
      this.show = !this.show
    },
  },
}
</script>
