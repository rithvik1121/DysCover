# DysCover - Philly CodeFest 2025

### Dyslexia is a condition that often flies under the radar when it comes to awareness and identification. DysCover is a system that allows teachers to monitor how their students perform across a small suite of tests that can highlight any signs of dyslexia their students may convey, while improving reading and writing performance classwide.

Dyslexia is incredibly difficult to identify and diagnose, especially at a young age. While our app cannot diagnose dyslexia, it aims to assess and evaluate the risk of a student having dyslexia by recording their performance across various reading and writing tests over time. Teachers can monitor their students' performance in these tests through an online dashboard, and assign learning modules of various difficulty. The dashboard also notifies teachers when a student's data indicates they could be showing signs of dyslexia. 
Through these tools a teacher can identify students who consistently exhibit behaviors aligning with dyslexia and, after consulting with their parents, pursue further action with a specially trained professional.

We focused on a couple of behaviors that are characteristic of dyslexia: mixing up letters or words while reading and writing, and stuttering while reading text out loud.

Our test consists of a short collection of simple prompts focusing on those behaviors asking a student to speak, type, and handwrite words. 
We used a variety of deep learning methods to analyze responses to these prompts and identify potential signs of dyslexia. 

First, we ask a student to read a word out loud, and use Whisper for speech-to-text to verify whether they spoke the correct word. 

We use the ElevenLabs voice generator for text-to-speech to allow our app to speak words, letters, and phrases without displaying them on screen to test a student's spelling ability.

We also ask students to write a short phrase (spoken by the voice generator) on a sheet of paper or whiteboard, and use GPT-4o to recognize how different a photo of their written phrase is from the given phrase.

Finally, we designed and trained a Convolutional Neural Network for stutter detection, a task for which not many resources are available. While pretrained language recognition models are applicable for stutter detection and versions of these models that are fine-tuned for stutter detection exist, there are not many models trained specially for this task. Furthermore, there are not many stutter detection datasets available. To that end, we extracted mel-spectrograms, zero crossing rate, and spectral flatness from waveforms provided by the Sep-28k stuttering dataset. These features are able to highlight any hesitating or stuttering in a waveform, making them incredibly effective for training our relatively small network. The model is able to reliably identify whether a student stutters while reading a word out loud.

By combining these multiple technologies into a single app, we aim to assist teachers in helping their students become better at reading and writing, and help address how overlooked dyslexia often is. 
