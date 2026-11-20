using UnityEngine;

public class ShakalLayerBinder : MonoBehaviour
{
    [SerializeField] Camera effectCamera;
    [SerializeField] GameObject[] objectsOnLayer;

    const string LayerName = "ShakalEffect";

    void Awake()
    {
        int layer = LayerMask.NameToLayer(LayerName);
        if (layer == -1)
        {
            Debug.LogError($"Слой '{LayerName}' не найден");
            return;
        }

        foreach (var go in objectsOnLayer)
            go.layer = layer;

        if (effectCamera != null)
            effectCamera.cullingMask = 1 << layer;
    }
}