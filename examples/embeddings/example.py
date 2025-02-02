#!/usr/bin/env python3
import llm

def embed_text():
    """Example of embedding text with Python."""
    model = llm.get_embedding_model("sentence-transformers/all-MiniLM-L6-v2")
    vector = model.embed("This is text to embed")
    print(f"Embedding vector: {vector[:5]}...")  # Show first 5 elements

def work_with_collections():
    """Example of working with collections."""
    collection = llm.Collection("entries", 
                              model_id="sentence-transformers/all-MiniLM-L6-v2")
    
    # Store items with metadata
    collection.embed_multi(
        [
            ("code", "Python implementation details"),
            ("docs", "Documentation and examples"),
            ("test", "Test suite and coverage"),
        ],
        store=True,
    )
    
    # Find similar items
    results = collection.similar("implementation guide")
    for result in results:
        print(f"Match: {result.id} - Score: {result.score}")

if __name__ == "__main__":
    embed_text()
    work_with_collections()
