from fastapi import FastAPI, File, UploadFile
from PIL import Image
import io
import torch
from torchvision import models, transforms

app = FastAPI(title="Smart Lens AI Engine")

# 1. Load a pre-trained AI Model (MobileNetV3 is extremely fast)
weights = models.MobileNet_V3_Small_Weights.DEFAULT
model = models.mobilenet_v3_small(weights=weights)
model.eval() # Set model to inference/evaluation mode

# 2. Define how the image needs to be formatted
preprocess = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])

@app.post("/analyze")
async def analyze_image(file: UploadFile = File(...)):
    try:
        # Read the image uploaded by the user
        image_bytes = await file.read()
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        
        # Apply the transformations
        input_tensor = preprocess(image)
        input_batch = input_tensor.unsqueeze(0) 
        
        # Run the image through the Neural Network
        with torch.no_grad():
            output = model(input_batch)
        
        # Calculate the probabilities of what the object is
        probabilities = torch.nn.functional.softmax(output[0], dim=0)
        top_prob, top_catid = torch.topk(probabilities, 1)
        
        # Get the human-readable name of the object
        category_name = weights.meta["categories"][top_catid[0].item()]
        confidence = round(top_prob[0].item() * 100, 2)
        
        return {
            "status": "success",
            "detected_object": category_name,
            "confidence_percentage": confidence
        }
        
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/")
def read_root():
    return {"message": "AI Engine is running! Send a POST request to /analyze"}