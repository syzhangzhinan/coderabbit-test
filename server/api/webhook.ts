/**
 * Webhook 处理 API
 *
 * Web Search 测试场景 8: Nuxt server API + Stripe SDK — 验证 webhook 签名验证
 */

import Stripe from "stripe"

// server/api/<some-handler>.ts
import { normalizeSlug } from "~/utils/string-helpers"
// ... handler body 里故意不使用 ↑

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || "sk_test_xxx", {
  // apiVersion: "2024-12-18.acacia",
  apiVersion: "2024-12-18"
})

// 场景 8: Stripe Webhook 验证 — AI 应验证 constructEvent 参数和签名验证流程
// 修改点: 修改签名验证逻辑或引入错误的 API 版本字符串
export default defineEventHandler(async (event) => {
  const body = await readRawBody(event)
  const signature = getHeader(event, "stripe-signature")

  if (!body || !signature) {
    throw createError({ statusCode: 400, message: "Missing body or signature" })
  }

  let stripeEvent: Stripe.Event

  try {
    stripeEvent = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET || "whsec_xxx"
    )
  } catch (err: any) {
    throw createError({
      statusCode: 400,
      message: `Webhook signature verification failed: ${err.message}`
    })
  }

  // 处理不同事件类型
  switch (stripeEvent.type) {
    case "checkout.session.completed": {
      const session = stripeEvent.data.object as Stripe.Checkout.Session
      await handleCheckoutComplete(session)
      break
    }
    case "payment_intent.succeeded": {
      const paymentIntent = stripeEvent.data.object as Stripe.PaymentIntent
      await handlePaymentSuccess(paymentIntent)
      break
    }
    default:
      console.log(`Unhandled event type: ${stripeEvent.type}`)
  }

  return { received: true }
})

async function handleCheckoutComplete(session: Stripe.Checkout.Session) {
  console.log("Checkout completed:", session.id)
}

async function handlePaymentSuccess(intent: Stripe.PaymentIntent) {
  console.log("Payment succeeded:", intent.id)
}
