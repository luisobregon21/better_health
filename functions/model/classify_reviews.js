const { Configuration, OpenAIApi } = require("openai");
const path = require('path')
require('dotenv').config({ 'path': path.resolve(__dirname, '../../.env') });

const configuration = new Configuration({
    apiKey: process.env.OPENAI_API_KEY,
});
const openai = new OpenAIApi(configuration);

exports.getOverallSentiment = async (req, res) => {
    const { texts } = req.body
    const expected_output = JSON.stringify({
        'overall': 'negative',
        'score': .72,
        'keywords': [{
            'tag': 'wait-time',
            'overall': 'negative',
            'score': .92,
        },
        {
            'tag': 'staff',
            'overall': 'negative',
            'score': .92,
        }
        ]
    })
    const question = `Can you classify the a text into one of these categories: "positive", "negative", "neutral".\
    After classifying can you extract keywords that a patient would want to know before hand about a hospital and tag them.\
    These is the output format I want: ${expected_output}.\
    \nThis is the text:`

    const final_question = `${question}\n ${texts}`
    try {
        const completion = await openai.createChatCompletion({
            model: "gpt-3.5-turbo",
            messages: [
                { "role": "system", "content": "You are a helpful hospital reviews analyser" },
                { "role": "user", "content": final_question },
            ]
        });
        const sentiments = completion.data.choices[0].message.content
        const jsonObject = JSON.parse(sentiments.substring(sentiments.indexOf('{'), sentiments.lastIndexOf('}') + 1));
        const finalAnalysis = {
            "overall": jsonObject.overall,
            "score": jsonObject.score,
            "keywords": jsonObject.keywords.filter((sentiment) => {
                if (sentiment.score >= 0.2) {
                    return sentiment
                }
            })
        }
        return res.status(200).json(finalAnalysis)

    } catch (err) {
        console.log('Error classifying reviews', err)
        return res.status(400).json({ message: err.message })
    }
}