import Flutter
import UIKit
import Altcraft

public class AltcraftSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let bridge = SdkBridge()
    let methodChannel = FlutterMethodChannel(name: "com.altcraft/sdk", binaryMessenger: registrar.messenger())
    methodChannel.setMethodCallHandler { call, result in
      bridge.handle(call, result: result)
    }
    let eventChannel = FlutterEventChannel(name: "com.altcraft/events", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(bridge)
  }
}

class SdkBridge: NSObject, FlutterStreamHandler {
  nonisolated(unsafe) private var eventSink: FlutterEventSink?
  private var eventSubscriptionCancelled = false

  public func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
    eventSubscriptionCancelled = false
    self.eventSink = eventSink
    SDKEvents.shared.subscribe { [weak self] event in
      guard let self, !self.eventSubscriptionCancelled else { return }
      let dict: [String: Any?] = self.eventToDict(event)
      let boxedDict = SendableBox(dict as Any?)
      let boxedSink = SendableBox(self.eventSink)
      DispatchQueue.main.async {
        guard let sink = boxedSink.get() as? FlutterEventSink,
              let d = boxedDict.get() as? [String: Any?] else { return }
        sink(d)
      }
    }
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSubscriptionCancelled = true
    eventSink = nil
    return nil
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize": handleInitialize(call, result: result)
    case "getPushToken": handleGetPushToken(result: result)
    case "setPushToken": handleSetPushToken(call, result: result)
    case "clear": handleClear(result: result)
    case "mobileEvent": handleMobileEvent(call)
    case "pushSubscribe": handlePushSubscribe(call)
    case "pushSuspend": handlePushSuspend(call)
    case "pushUnSubscribe": handlePushUnSubscribe(call)
    case "unSuspendPushSubscription": handleUnSuspend(result: result)
    case "getStatusOfLatestSubscription": handleGetLatestStatus(result: result)
    case "getStatusOfLatestSubscriptionForProvider": handleGetLatestStatusForProvider(call, result: result)
    case "getStatusForCurrentSubscription": handleGetCurrentStatus(result: result)
    case "updateProfileFields": handleUpdateProfileFields(call)
    case "forcedTokenUpdate": handleForcedTokenUpdate(result: result)
    case "deleteDeviceToken": handleDeleteDeviceToken(call, result: result)
    case "changePushProviderPriorityList": handleChangePriority(call, result: result)
    case "isAltcraftPush": result(false)
    case "takePush", "deliveryEvent", "openEvent": break
    case "requestNotificationPermission", "unlockInitialOperationsInThisSession": result(nil)
    case "setAppGroup": handleSetAppGroup(call)
    case "setUserDefaultsValue": handleSetUserDefaults(call)
    case "unsubscribeFromEvents": handleUnsubscribeFromEvents(result: result)
    default:
      result(FlutterError(code: "NOT_IMPLEMENTED", message: "\(call.method) not implemented for iOS", details: nil))
    }
  }

  // Sendable wrapper: captures FlutterResult via @unchecked Sendable box
  private final class ResultAction: @unchecked Sendable {
    private let resultBox: ResultBox
    private let valueProvider: ValueProvider

    init(_ result: @escaping FlutterResult, _ value: @autoclosure @escaping () -> Any?) {
      self.resultBox = ResultBox(result)
      self.valueProvider = ValueProvider(value)
    }

    func execute() {
      resultBox.call(valueProvider.get() ?? NSNull())
    }
  }

  private final class ResultBox: @unchecked Sendable {
    nonisolated(unsafe) private var result: FlutterResult?
    init(_ result: @escaping FlutterResult) { self.result = result }
    func call(_ value: Any) {
      guard let r = self.result else { return }
      let boxedValue = SendableBox(value)
      DispatchQueue.main.async {
        r(boxedValue.get() as Any? ?? NSNull())
      }
    }
  }

  private final class ValueProvider: @unchecked Sendable {
    private let closure: () -> Any?
    init(_ closure: @escaping () -> Any?) { self.closure = closure }
    func get() -> Any? { closure() }
  }

  private final class SendableBox: @unchecked Sendable {
    private let closure: () -> Any?
    init(_ value: Any?) { self.closure = { value } }
    func get() -> Any? { closure() }
  }

  // MARK: - Handlers

  private func handleInitialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let config = call.arguments as? [String: Any],
          let apiUrl = config["apiUrl"] as? String else {
      result(FlutterError(
      code: "ALTCRAFT_INIT_INVALID_CONFIG",
      message: "config/apiUrl missing",
       details: nil)
       )
      return
    }
    let appInfoDict = config["appInfo"] as? [String: Any]
    let providerList = (config["providerPriorityList"] as? [Any])?.compactMap { $0 as? String }
    let enableLogging = config["enableLogging"] as? Bool
    let rToken = config["rToken"] as? String
    let appInfo: AppInfo? = appInfoDict.map {
      AppInfo(
        appID: $0["appID"] as? String ?? "",
        appIID: $0["appIID"] as? String ?? "",
        appVer: $0["appVer"] as? String ?? "1.0.0"
      )
    }
    guard let altcraftConfig = AltcraftConfiguration.Builder()
      .setApiUrl(apiUrl)
      .setRToken(rToken)
      .setAppInfo(appInfo)
      .setProviderPriorityList(providerList)
      .setEnableLogging(enableLogging)
      .build() else {
      result(nil)
      return
    }
    let action = ResultAction(result, nil as Any?)
    AltcraftSDK.shared.initialization(configuration: altcraftConfig) { _ in
      action.execute()
    }
  }

  private func handleGetPushToken(result: @escaping FlutterResult) {
    let tokenHolder = TokenHolder()
    let action = ResultAction(result, tokenHolder.dict())
    AltcraftSDK.shared.pushTokenFunctions.getPushToken { tokenData in
      tokenHolder.set(tokenData.map { ($0.provider, $0.token) })
      action.execute()
    }
  }

  private final class TokenHolder: @unchecked Sendable {
    nonisolated(unsafe) private var data: (String, String)?
    func set(_ d: (String, String)?) { data = d }
    func dict() -> Any? { data.map { ["provider": $0.0, "token": $0.1] } }
  }

  private func handleSetPushToken(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let provider = args["provider"] as? String else {
      result(FlutterError(code: "ERR", message: "provider missing", details: nil))
      return
    }
    AltcraftSDK.shared.pushTokenFunctions.setPushToken(provider: provider, pushToken: args["token"] as? String)
    result(nil)
  }

  private func handleClear(result: @escaping FlutterResult) {
    let action = ResultAction(result, nil as Any?)
    AltcraftSDK.shared.clear { action.execute() }
  }

  private func handleMobileEvent(_ call: FlutterMethodCall) {
    guard let args = call.arguments as? [String: Any],
          let sid = args["sid"] as? String,
          let eventName = args["eventName"] as? String else { return }
    let utmMap = args["utm"] as? [String: Any]
    let utm: UTM? = utmMap.map {
      UTM(campaign: $0["campaign"] as? String, content: $0["content"] as? String,
          keyword: $0["keyword"] as? String, medium: $0["medium"] as? String,
          source: $0["source"] as? String, temp: $0["temp"] as? String)
    }
    let subscription: (any Subscription)? = (args["subscription"] as? [String: Any]).flatMap { self.toSubscription(dict: $0) }
    AltcraftSDK.shared.mobileEventFunctions.mobileEvent(
      sid: sid, eventName: eventName,
      sendMessageId: args["sendMessageId"] as? String,
      payload: (args["payload"] as? [String: Any])?.mapValues { String(describing: $0) },
      matching: (args["matching"] as? [String: Any])?.mapValues { String(describing: $0) },
      matchingType: args["matchingType"] as? String,
      profileFields: (args["profileFields"] as? [String: Any])?.mapValues { String(describing: $0) },
      subscription: subscription, utm: utm)
  }

  private func handlePushSubscribe(_ call: FlutterMethodCall) {
    guard let args = call.arguments as? [String: Any] else { return }
    AltcraftSDK.shared.pushSubscriptionFunctions.pushSubscribe(
      sync: args["sync"] as? Bool ?? true,
      profileFields: args["profileFields"] as? [String: Any],
      customFields: args["customFields"] as? [String: Any],
      cats: (args["cats"] as? [[String: Any]])?.map { self.toCategoryData(dict: $0) },
      replace: args["replace"] as? Bool,
      skipTriggers: args["skipTriggers"] as? Bool)
  }

  private func handlePushSuspend(_ call: FlutterMethodCall) {
    guard let args = call.arguments as? [String: Any] else { return }
    AltcraftSDK.shared.pushSubscriptionFunctions.pushSuspend(
      sync: args["sync"] as? Bool ?? true,
      profileFields: args["profileFields"] as? [String: Any],
      customFields: args["customFields"] as? [String: Any],
      cats: (args["cats"] as? [[String: Any]])?.map { self.toCategoryData(dict: $0) },
      replace: args["replace"] as? Bool,
      skipTriggers: args["skipTriggers"] as? Bool)
  }

  private func handlePushUnSubscribe(_ call: FlutterMethodCall) {
    guard let args = call.arguments as? [String: Any] else { return }
    AltcraftSDK.shared.pushSubscriptionFunctions.pushUnSubscribe(
      sync: args["sync"] as? Bool ?? true,
      profileFields: args["profileFields"] as? [String: Any],
      customFields: args["customFields"] as? [String: Any],
      cats: (args["cats"] as? [[String: Any]])?.map { self.toCategoryData(dict: $0) },
      replace: args["replace"] as? Bool,
      skipTriggers: args["skipTriggers"] as? Bool)
  }

  private func handleUnSuspend(result: @escaping FlutterResult) {
    let holder = ResponseHolder()
    let action = ResultAction(result, holder.dict())
    AltcraftSDK.shared.pushSubscriptionFunctions.unSuspendPushSubscription { (response: ResponseWithHttp?) in
      holder.set(response)
      action.execute()
    }
  }

  private func handleGetLatestStatus(result: @escaping FlutterResult) {
    let holder = ResponseHolder()
    let action = ResultAction(result, holder.dict())
    AltcraftSDK.shared.pushSubscriptionFunctions.getStatusOfLatestSubscription { (response: ResponseWithHttp?) in
      holder.set(response)
      action.execute()
    }
  }

  private func handleGetLatestStatusForProvider(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else { result(nil); return }
    let provider = args["provider"] as? String
    let holder = ResponseHolder()
    let action = ResultAction(result, holder.dict())
    AltcraftSDK.shared.pushSubscriptionFunctions.getStatusOfLatestSubscriptionForProvider(
      provider: provider) { (response: ResponseWithHttp?) in
      holder.set(response)
      action.execute()
    }
  }

  private func handleGetCurrentStatus(result: @escaping FlutterResult) {
    let holder = ResponseHolder()
    let action = ResultAction(result, holder.dict())
    AltcraftSDK.shared.pushSubscriptionFunctions.getStatusForCurrentSubscription { (response: ResponseWithHttp?) in
      holder.set(response)
      action.execute()
    }
  }

  private final class ResponseHolder: @unchecked Sendable {
    nonisolated(unsafe) private var response: ResponseWithHttp?
    func set(_ r: ResponseWithHttp?) { self.response = r }
    func dict() -> Any? {
      guard let r = response else { return nil }
      var dict: [String: Any?] = [:]
      dict["httpCode"] = r.httpCode as Any?
      if let resp = r.response {
        do {
          let data = try JSONEncoder().encode(resp)
          if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            dict["response"] = json
          }
        } catch {
          dict["response"] = nil
        }
      } else {
        dict["response"] = nil
      }
      return dict
    }
  }

  private func handleUpdateProfileFields(_ call: FlutterMethodCall) {
    guard let args = call.arguments as? [String: Any] else { return }
    AltcraftSDK.shared.profileFunctions.updateProfileFields(
      profileFields: args["profileFields"] as? [String: Any],
      skipTriggers: args["skipTriggers"] as? Bool)
  }

  private func handleForcedTokenUpdate(result: @escaping FlutterResult) {
    let action = ResultAction(result, nil as Any?)
    AltcraftSDK.shared.pushTokenFunctions.forcedTokenUpdate { action.execute() }
  }

  private func handleDeleteDeviceToken(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let provider = args["provider"] as? String else {
      result(FlutterError(code: "ERR", message: "provider missing", details: nil))
      return
    }
    let action = ResultAction(result, nil as Any?)
    AltcraftSDK.shared.pushTokenFunctions.deleteDeviceToken(provider: provider) { action.execute() }
  }

  private func handleChangePriority(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "ERR", message: "args is null", details: nil))
      return
    }
    let priorityList = (args["priorityList"] as? [Any])?.compactMap { $0 as? String } ?? []
    AltcraftSDK.shared.pushTokenFunctions.changePushProviderPriorityList(priorityList)
    result(nil)
  }

  private func handleSetAppGroup(_ call: FlutterMethodCall) {
    guard let args = call.arguments as? [String: Any],
          let groupName = args["groupName"] as? String else { return }
    AltcraftSDK.shared.setAppGroup(groupName: groupName)
  }

  private func handleSetUserDefaults(_ call: FlutterMethodCall) {
    guard let args = call.arguments as? [String: Any],
          let key = args["key"] as? String else { return }
    let value = args["value"] as? String
    if let suiteName = args["suiteName"] as? String {
      UserDefaults(suiteName: suiteName)?.setValue(value, forKey: key)
    } else {
      UserDefaults.standard.setValue(value, forKey: key)
    }
  }

  private func handleUnsubscribeFromEvents(result: @escaping FlutterResult) {
    SDKEvents.shared.unsubscribe()
    eventSink = nil
    eventSubscriptionCancelled = true
    result(nil)
  }

  // MARK: - Helpers

    private func eventToDict(_ event: Event) -> [String: Any?] {
    let type: String
    if event is RetryEvent { type = "retryError" }
    else if event is ErrorEvent { type = "error" }
    else { type = "event" }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    formatter.locale = Locale(identifier: "en_US")
    formatter.timeZone = TimeZone.current
    let timestamp = formatter.string(from: event.date)
    return [
      "function": event.function,
      "code": event.eventCode ?? NSNull(),
      "message": event.message ?? "",
      "type": type,
      "value": sanitizeValue(event.value) ?? NSNull(),
      "timestamp": timestamp
    ]
  }

  private func sanitizeValue(_ value: [String: Any]?) -> [String: Any?]? {
    guard let value else { return nil }
    var sanitized: [String: Any?] = [:]
    for (key, val) in value {
      if let responseWithHttp = val as? ResponseWithHttp {
        sanitized[key] = responseToDict(responseWithHttp)
      } else if let response = val as? Response {
        sanitized[key] = responseToJsonDict(response)
      } else {
        sanitized[key] = val
      }
    }
    return sanitized
  }

  private func responseToJsonDict(_ response: Response) -> [String: Any?]? {
    do {
      let data = try JSONEncoder().encode(response)
      return try JSONSerialization.jsonObject(with: data) as? [String: Any?]
    } catch {
      return nil
    }
  }

  private func responseToDict(_ response: ResponseWithHttp?) -> [String: Any?]? {
    guard let response else { return nil }
    var dict: [String: Any?] = [:]
    dict["httpCode"] = response.httpCode as Any?
    if let resp = response.response {
      do {
        let data = try JSONEncoder().encode(resp)
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
          dict["response"] = json
        }
      } catch {
        dict["response"] = nil
      }
    } else {
      dict["response"] = nil
    }
    return dict
  }

  private func toCategoryData(dict: [String: Any]) -> CategoryData {
    CategoryData(name: dict["name"] as? String, title: dict["title"] as? String,
                 steady: dict["steady"] as? Bool, active: dict["active"] as? Bool)
  }

  private func toSubscription(dict: [String: Any]) -> (any Subscription)? {
    let type = dict["type"] as? String ?? ""
    let cf = toJV(dict["custom_fields"] as? [String: Any])
    let cats = dict["cats"] as? [String]
    let rid = (dict["resourceId"] as? Int) ?? 0
    let st = dict["status"] as? String
    let pr = dict["priority"] as? Int
    switch type {
    case "email": return EmailSubscription(resourceId: rid, email: dict["email"] as? String ?? "", status: st, priority: pr, customFields: cf, cats: cats)
    case "sms": return SmsSubscription(resourceId: rid, phone: dict["phone"] as? String ?? "", status: st, priority: pr, customFields: cf, cats: cats)
    case "push": return PushSubscription(resourceId: rid, provider: dict["provider"] as? String ?? "", subscriptionId: dict["subscriptionId"] as? String ?? "", status: st, priority: pr, customFields: cf, cats: cats)
    case "cc_data": return CcDataSubscription(resourceId: rid, channel: dict["channel"] as? String ?? "", ccData: toJV(dict["cc_data"] as? [String: Any]) ?? [:], status: st, priority: pr, customFields: cf, cats: cats)
    default: return nil
    }
  }

  private func toJV(_ dict: [String: Any]?) -> [String: JSONValue]? {
    guard let dict else { return nil }
    var r: [String: JSONValue] = [:]
    for (k, v) in dict { r[k] = toJV(v) }
    return r
  }

  private func toJV(_ value: Any) -> JSONValue {
    if let s = value as? String { return .string(s) }
    if let b = value as? Bool { return .bool(b) }
    if let n = value as? Int { return .number(Double(n)) }
    if let n = value as? Double { return .number(n) }
    if let a = value as? [Any] { return .array(a.map { toJV($0) }) }
    if let d = value as? [String: Any] { return .object(toJV(d) ?? [:]) }
    if value is NSNull { return .null }
    return .string(String(describing: value))
  }
}
