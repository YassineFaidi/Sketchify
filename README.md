# Sketchify

*Transform your face sketches into realistic portraits with Sketchify!*

---

## Overview

**Sketchify** is a specialized face drawing application that allows users to draw freehand face sketches on a canvas and send them to a custom API powered by the **DeepFaceDrawing-Jittor** model for processing. The model generates realistic face portraits from your sketches, offering a seamless and interactive experience. This app is built with **Flutter** and integrates with an API that uses advanced AI to process face drawings and generate photorealistic results.

---

## Features

- **Interactive Face Drawing**: Draw freehand face sketches on a blank canvas with real-time touch support.
- **AI-Powered Processing**: Send your face sketch to a backend API powered by the DeepFaceDrawing-Jittor model for realistic face generation.
- **Loading State**: Display a loading state with a beautiful progress indicator while waiting for the AI model to process your sketch.
- **Customizable API URL**: Easily change the API URL via the settings menu.
- **Clean & Beautiful UI**: A minimalist interface with a soothing color scheme and user-friendly controls.

---

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Custom API with DeepFaceDrawing-Jittor model
- **AI Model**: DeepFaceDrawing-Jittor for face sketch-to-photo generation
- **Image Processing**: Advanced AI processing of face sketches to generate realistic portraits.

---

## Getting Started

### Prerequisites

To run Sketchify locally, you'll need the following:

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- A **working API** to process images (or you can use your own API endpoint).

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/YassineFaidi/Sketchify.git
   cd Sketchify
   ```

2. Install the dependencies:

   ```bash
   flutter pub get
   ```

3. Ensure you have a running API that processes images and update the API URL in the app. The default URL is set to:

   ```dart
   String _apiUrl = 'https://your-api-url.com';
   ```

4. Run the app:

   ```bash
   flutter run
   ```

---

## Usage

1. **Draw a Face**: Use your finger or stylus to draw a face sketch on the canvas area at the bottom of the screen.
2. **Generate**: Tap the **Generate** button (star icon) to send your face sketch to the DeepFaceDrawing-Jittor model for processing.
3. **View the Result**: The AI-generated realistic face portrait will appear at the top of the screen. If no image appears, try resetting your drawing or check the API connection.
4. **Reset Drawing**: Tap the **Reset** button (refresh icon) to clear the canvas and start a new face sketch.
5. **Change API URL**: Tap the **Settings** button (gear icon) in the top right corner to change the API URL if needed.

---

## API Endpoint

- **POST `/process-image`**: This endpoint accepts the uploaded face sketch and returns the AI-generated realistic face portrait.

  **Request**:
  - **Body**: Multipart form-data containing a face sketch image file (PNG format recommended).

  **Response**:
  - An AI-generated realistic face portrait in **JPG** format will be returned in the response.

---

## AI Model

Sketchify uses the **DeepFaceDrawing-Jittor** model, which is specifically designed for converting hand-drawn face sketches into realistic face portraits. The model leverages advanced deep learning techniques to understand facial features and generate high-quality, photorealistic results from simple sketches.

---

## Customization

- **App Color Scheme**: The app uses a light blue color (`#bfd7ed`) for the main theme. You can change the colors by modifying the `theme` in `main.dart`.
- **API URL**: Change the default API URL by accessing the settings and providing a new URL.

---

## Contributing

We welcome contributions! If you'd like to improve this app, please fork the repository, make your changes, and submit a pull request.

---

## License

This project is open-source and available under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Contact

Created by **Faidi Yassine** - yassine.faidi.117@gmail.com

Feel free to reach out for suggestions, issues, or collaboration!

---

Enjoy drawing! ✏️🎨
