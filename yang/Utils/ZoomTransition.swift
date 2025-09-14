import UIKit
import SwiftUI

// MARK: - Zoom Transition Animation Controller
class ZoomTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    private let isPresenting: Bool
    private let originFrame: CGRect

    init(isPresenting: Bool, originFrame: CGRect) {
        self.isPresenting = isPresenting
        self.originFrame = originFrame
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isPresenting ? 0.4 : 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        if isPresenting {
            animatePresentation(using: transitionContext, containerView: containerView)
        } else {
            animateDismissal(using: transitionContext, containerView: containerView)
        }
    }

    private func animatePresentation(using transitionContext: UIViewControllerContextTransitioning, containerView: UIView) {
        guard let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        let finalFrame = transitionContext.finalFrame(for: transitionContext.viewController(forKey: .to)!)

        // 초기 상태: 터치 지점에서 작은 원형으로 시작
        toView.frame = finalFrame
        toView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        toView.center = CGPoint(x: originFrame.midX, y: originFrame.midY)
        toView.alpha = 0.0

        containerView.addSubview(toView)

        // 애니메이션: 전체 화면으로 확장
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.2,
            options: [.curveEaseOut],
            animations: {
                toView.transform = .identity
                toView.center = CGPoint(x: finalFrame.midX, y: finalFrame.midY)
                toView.alpha = 1.0
            },
            completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }

    private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning, containerView: UIView) {
        guard let fromView = transitionContext.view(forKey: .from),
              let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        // toView를 containerView에 추가하여 뒤의 뷰가 보이도록 설정
        containerView.insertSubview(toView, belowSubview: fromView)
        containerView.backgroundColor = UIColor.clear

        // 투명도가 먼저 변화한 후 크기 변화
        let totalDuration = 0.3
        let alphaDelay: TimeInterval = 0
        let alphaDuration = totalDuration * 0.8
        let scaleDelay = 0.0
        let scaleDuration = totalDuration * 0.8

        // 투명도 애니메이션 (먼저 시작)
        UIView.animate(
            withDuration: alphaDuration,
            delay: alphaDelay,
            options: [.curveEaseOut],
            animations: {
                fromView.alpha = 0.0
            }
        )

        // 크기 및 위치 애니메이션 (조금 늦게 시작)
        UIView.animate(
            withDuration: scaleDuration,
            delay: scaleDelay,
            options: [.curveEaseIn],
            animations: {
                fromView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                fromView.center = CGPoint(x: self.originFrame.midX, y: self.originFrame.midY)
            },
            completion: { _ in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}

// MARK: - Transitioning Delegate
class ZoomTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {

    private let originFrame: CGRect

    init(originFrame: CGRect) {
        self.originFrame = originFrame
        super.init()
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ZoomTransitionAnimator(isPresenting: true, originFrame: originFrame)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ZoomTransitionAnimator(isPresenting: false, originFrame: originFrame)
    }
}
