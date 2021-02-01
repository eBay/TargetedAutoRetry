import XCTest

public protocol TargetedAutoRetry {
	/// Generic auto retry logic, using closures.  This can be used in cases where UI tests are flakey and content is not loading
	/// in a reasonable time frame.  It returns the retryAttempt integer, which can be used to record the flakiness.  For example,
	/// if a test action is only successful after the third attempt, this indicates flakiness which may mean a bug was found.  But,
	/// in many cases, such as launch(), if the automation doesn't launch the app properly, there's no point in failing the test if a
	/// few retries will get it to launch correctly.
	///
	/// - parameter mainAction: closure containing the action which may need to be retried if not initially successful
	/// - parameter successCondition: closure condition determining whether or not the mainAction needs to be retried
	/// - parameter resetSteps: optional closure containing the steps (if needed) to reset the state for the mainAction
	/// - parameter retryAttempts: number of retry attempts (integer) to try before throwing an error
	/// - parameter actionDescription: optional custom action description for use in logging and error reporting
	/// - parameter file:        File this method was called from for diagnostics
	/// - parameter line:        Line this method was called from for diagnostics
	/// - returns: the number (Int) of attempts before the autoRetry completed.
	func autoRetry(mainAction: () -> (),
				   successCondition: () -> Bool?,
				   resetSteps: (() -> ())?,
				   retryAttempts: Int,
				   actionDescription: String?,
				   failTestOnFailure: Bool,
				   file: StaticString,
				   line: UInt) -> Int
}

public extension TargetedAutoRetry {
	/// Generic auto retry logic, using closures.  This can be used in cases where UI tests are flakey and content is not loading
	/// in a reasonable time frame.  It returns the retryAttempt integer, which can be used to record the flakiness.  For example,
	/// if a test action is only successful after the third attempt, this indicates flakiness which may mean a bug was found.  But,
	/// in many cases, such as launch(), if the automation doesn't launch the app properly, there's no point in failing the test if a
	/// few retries will get it to launch correctly.
	///
	/// - parameter mainAction: closure containing the action which may need to be retried if not initially successful
	/// - parameter successCondition: closure condition determining whether or not the mainAction needs to be retried
	/// - parameter resetSteps: optional closure containing the steps (if needed) to reset the state for the mainAction
	/// - parameter retryAttempts: number of retry attempts (integer) to try before throwing an error
	/// - parameter actionDescription: optional custom action description for use in logging and error reporting
	/// - parameter file:        File this method was called from for diagnostics
	/// - parameter line:        Line this method was called from for diagnostics
	/// - returns: the number (Int) of attempts before the autoRetry completed.
	@discardableResult
	func autoRetry(mainAction: () -> (),
				   successCondition: () -> Bool?,
				   resetSteps: (() -> ())? = nil,
				   retryAttempts: Int =  3,
				   actionDescription: String? = nil,
				   failTestOnFailure: Bool = true,
				   file: StaticString = #file,
				   line: UInt = #line) -> Int {
		var actionSuccessful: Bool = false
		var retryAttempt: Int = 0
		
		while actionSuccessful == false && retryAttempt <= retryAttempts {
            let attemptsRemaining = retryAttempts - retryAttempt
            let attemptsRemainingText = (retryAttempt == 0) ? "" : ((". Retry attempt: \(retryAttempt)") + ". Attempts remaining: \(attemptsRemaining).")
            // XCTContext.runActivity logs information for individual test steps for reporting
            XCTContext.runActivity(named: ((retryAttempt == 0) ? "" : "♻️♻️♻️▶️  [NEW RETRY ACTION: \(retryAttempt)] ") + (actionDescription ?? "Action. ") + attemptsRemainingText) { _ in
                mainAction()
            }
            
            let successConditionText = ((retryAttempt == 0) ? "" : "♻️♻️♻️⏱  [SUCCESS CONDITION: \(retryAttempt)] ") + " Wait for Success Condition for action: "
            actionSuccessful = XCTContext.runActivity(named: successConditionText + (actionDescription ?? "") + attemptsRemainingText){ _ in
                successCondition() ?? false
            }
            
            if actionSuccessful == false {
                var statusMessage = "♻️♻️♻️    [RETRY INFO: \(retryAttempt)] " + (actionDescription ?? "Action") + " Attempt Unsuccessful. Number of attempts: \(retryAttempt + 1).  Attempts remaining: \(attemptsRemaining)."
                if retryAttempt < retryAttempts {
                    statusMessage += "  Retrying."
                } else {
                    statusMessage += "  No more retries will be attempted."
                }
                XCTContext.runActivity(named: statusMessage) { _ in }
                
                if let reset = resetSteps,
                    retryAttempt < retryAttempts {
                    
                    var resetActionText = "♻️♻️♻️⏪  [RESET STEPS: \(retryAttempt)] Run Reset Steps to Retry action"
                    if let actionDescription = actionDescription {
                        resetActionText += ": \(actionDescription)"
                    }
                    XCTContext.runActivity(named: "\(resetActionText). \(attemptsRemainingText)"){ _ in
                        reset()
                    }
                }
                
                retryAttempt += 1
            }
        }
        
        if actionSuccessful == false {
            var failText = "♻️♻️♻️❌ [FAIL] Auto Retry failed \(retryAttempts) times for action: " + (actionDescription ?? "") + "  No more retries will be attempted."
            if failTestOnFailure == true {
                XCTAssert(actionSuccessful, failText + " Failing test.", file: file, line: line)
            } else {
                failText += ".  Moving on to the next step without failing the test."
                XCTContext.runActivity(named: failText) { _ in }
            }
        } else if retryAttempt > 0 {
            XCTContext.runActivity(named: "♻️♻️♻️ " + (actionDescription ?? "Action") + " required \(retryAttempt) retry attempts before success.") { _ in }
        }
        
        return retryAttempt
	}
}
