ServiceHub = require '../src/service-hub'

describe "ServiceHub", ->
  hub = null

  beforeEach ->
    hub = new ServiceHub

  describe "::consume(keyPath, versionString, callback)", ->
    it "invokes the callback with existing service provisions that match the key path and version range", ->
      hub.provide "a", "1.0.0", x: 1
      hub.provide "a", "1.1.0", y: 2
      hub.provide "b", "1.0.0", z: 3

      services = []
      hub.consume "a", "^1.0.0", (service) -> services.push(service)

      expect(services).toEqual [{x: 1}, {y: 2}]

    it "invokes the callback with future service provisions that match the key path and version range", ->
      services = []
      hub.consume "a", "^1.0.0", (service) -> services.push(service)

      hub.provide "a", "1.0.0", x: 1
      hub.provide "a", "1.1.0", y: 2
      hub.provide "b", "1.0.0", z: 3

      expect(services).toEqual [{x: 1}, {y: 2}]

    it "returns a disposable that removes the consumer", ->
      services = []
      disposable = hub.consume "a", "^1.0.0", (service) -> services.push(service)

      hub.provide "a", "1.0.0", x: 1
      disposable.dispose()
      hub.provide "a", "1.1.0", y: 2

      expect(services).toEqual [{x: 1}]

    it "can specify a key path that navigates into the contents of a service", ->
      hub.provide "a", "1.0.0", b: c: 1
      hub.provide "a", "1.0.0", d: e: 2

      services = []
      hub.consume "a.b", "^1.0.0", (service) -> services.push(service)

      expect(services).toEqual [{c: 1}]

    it "can specify a key path that's shorter than the key path passed to ::provide", ->
      hub.provide "a.b", "1.0.0", c: 1
      hub.provide "a.d", "1.0.0", e: 2

      services = []
      hub.consume "a", "^1.0.0", (service) -> services.push(service)

      expect(services).toEqual [{b: c: 1}, {d: e: 2}]

  describe "::provide(keyPath, version, service)", ->
    it "returns a disposable that removes the provider", ->
      disposable1 = hub.provide "a", "1.0.0", x: 1
      disposable2 = hub.provide "a", "1.1.0", y: 2

      disposable1.dispose()

      services = []
      disposable = hub.consume "a", "^1.0.0", (service) -> services.push(service)
      expect(services).toEqual [{y: 2}]