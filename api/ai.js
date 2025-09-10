export default async function handler(req, res) {
  if (req.method === 'POST') {
    const { prompt } = req.body;
    return res.status(200).json({ reply: `You said: ${prompt}` });
  }
  res.status(200).json({ message: "Hello from Groq Proxy!" });
}
