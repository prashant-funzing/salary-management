let csrf;
export async function api(path, options = {}) {
  const response = await fetch(`/api${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": csrf || "",
      ...options.headers,
    },
  });
  const data =
    response.status === 204
      ? null
      : response.headers.get("content-type")?.includes("application/json")
        ? await response.json()
        : {
            error:
              "The server could not complete this request. Please try again.",
          };
  if (!response.ok)
    throw new Error(
      data?.error || data?.errors?.join("\n") || "Request failed",
    );
  if (data?.csrf_token) csrf = data.csrf_token;
  return data;
}
export const money = (amount, currency = "INR") =>
  new Intl.NumberFormat(currency === "INR" ? "en-IN" : "en-US", {
    style: "currency",
    currency,
    maximumFractionDigits: currency === "JPY" ? 0 : 2,
  }).format(Number(amount));
export const today = () => new Date().toLocaleDateString("en-CA");
